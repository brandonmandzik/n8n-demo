# n8n application secrets management

# Random encryption key (32 bytes base64 encoded)
resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = false # Base64-safe characters only
}

# Random basic auth password
resource "random_password" "n8n_basic_auth_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager secret for n8n application secrets
resource "aws_secretsmanager_secret" "n8n_app_secrets" {
  name_prefix             = "${local.cluster_name}-n8n-app-"
  description             = "n8n application secrets (encryption key, basic auth)"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "n8n_app_secrets" {
  secret_id = aws_secretsmanager_secret.n8n_app_secrets.id
  secret_string = jsonencode({
    encryption_key        = random_password.n8n_encryption_key.result
    basic_auth_user       = "admin"
    basic_auth_password   = random_password.n8n_basic_auth_password.result
  })
}
