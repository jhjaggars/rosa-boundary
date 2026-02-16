output "client_id" {
  description = "AWS SRE Access client ID"
  value       = keycloak_openid_client.aws_sre.client_id
}

output "authorization_endpoint" {
  description = "OIDC authorization endpoint"
  value       = "${var.keycloak_url}/realms/${var.keycloak_realm}/protocol/openid-connect/auth"
}

output "token_endpoint" {
  description = "OIDC token endpoint"
  value       = "${var.keycloak_url}/realms/${var.keycloak_realm}/protocol/openid-connect/token"
}

output "issuer_url" {
  description = "OIDC issuer URL"
  value       = "${var.keycloak_url}/realms/${var.keycloak_realm}"
}
