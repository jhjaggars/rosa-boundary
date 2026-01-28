# AWS IAM OIDC Provider for Keycloak
resource "aws_iam_openid_connect_provider" "keycloak" {
  url = var.keycloak_issuer_url

  client_id_list = [
    var.oidc_client_id
  ]

  thumbprint_list = [
    var.keycloak_thumbprint
  ]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.stage}-keycloak-oidc"
  })
}

# Federated role for OIDC-authenticated SRE users
resource "aws_iam_role" "oidc_sre" {
  name                 = "${var.project}-${var.stage}-oidc-sre-role"
  max_session_duration = var.oidc_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.keycloak.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.keycloak_issuer_url, "https://", "")}:aud" = var.oidc_client_id
        }
        # Require sre-team group membership
        "ForAnyValue:StringEquals" = {
          "${replace(var.keycloak_issuer_url, "https://", "")}:groups" = "sre-team"
        }
      }
    }]
  })

  # Minimal permissions for ECS Exec only
  inline_policy {
    name = "ecs-exec-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecs:ExecuteCommand"
          ]
          Resource = [
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.main.name}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:DescribeClusters",
            "ecs:ListClusters",
            "ecs:DescribeTaskDefinition"
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.stage}-oidc-sre-role"
  })
}
