# Aurora database credentials management

# Random password for master user
resource "random_password" "aurora_master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager secret for Aurora credentials
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name_prefix             = "${local.aurora_cluster_identifier}-credentials-"
  description             = "Aurora PostgreSQL credentials for n8n"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = local.aurora_master_username
    password = random_password.aurora_master_password.result
    engine   = "postgres"
    host     = aws_rds_cluster.aurora.endpoint
    port     = tostring(aws_rds_cluster.aurora.port)
    dbname   = local.aurora_database_name
  })
}
