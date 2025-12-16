# KMS key for ECS Exec session encryption
resource "aws_kms_key" "exec_session" {
  description             = "KMS key for ECS Exec session encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.stage}-exec-session-key"
  })
}

resource "aws_kms_alias" "exec_session" {
  name          = "alias/${var.project}-${var.stage}-exec-session"
  target_key_id = aws_kms_key.exec_session.key_id
}
