# Aurora Serverless v2 PostgreSQL Configuration
# Drop-in replacement for in-cluster PostgreSQL StatefulSet

# Check for existing snapshots to restore from (for serverless lifecycle)
data "aws_db_cluster_snapshot" "latest" {
  count                 = 1
  db_cluster_identifier = local.aurora_cluster_identifier
  most_recent           = true
  snapshot_type         = "manual" # Final snapshots are manual type
}

# DB subnet group using existing private subnets
resource "aws_db_subnet_group" "aurora" {
  name_prefix = "${local.aurora_cluster_identifier}-"
  description = "Subnet group for Aurora cluster in private subnets"
  subnet_ids  = local.aurora_subnet_ids

  tags = merge(local.tags, {
    Name = "${local.aurora_cluster_identifier}-subnet-group"
  })
}

# RDS cluster parameter group for PostgreSQL 15
resource "aws_rds_cluster_parameter_group" "aurora" {
  name_prefix = "${local.aurora_cluster_identifier}-"
  family      = "aurora-postgresql15"
  description = "Custom parameter group for Aurora PostgreSQL 15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = local.tags
}

# Aurora Serverless v2 cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = local.aurora_cluster_identifier
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.8"
  database_name      = local.aurora_database_name
  master_username    = local.aurora_master_username
  master_password    = random_password.aurora_master_password.result

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]
  port                   = 5432

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"

  # Serverless lifecycle: keep protection off, but always create final snapshot
  deletion_protection = false
  skip_final_snapshot = false
  final_snapshot_identifier = "${local.aurora_cluster_identifier}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Restore from latest snapshot if available (for serverless restore workflow)
  snapshot_identifier = length(data.aws_db_cluster_snapshot.latest) > 0 ? try(data.aws_db_cluster_snapshot.latest[0].id, null) : null

  storage_encrypted = true

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  enabled_cloudwatch_logs_exports = ["postgresql"]

  apply_immediately = false

  tags = merge(local.tags, {
    Name = local.aurora_cluster_identifier
  })
}

# Aurora cluster instances (Multi-AZ)
resource "aws_rds_cluster_instance" "aurora" {
  count              = 2
  identifier         = "${local.aurora_cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  performance_insights_enabled = false
  monitoring_interval          = 0
  auto_minor_version_upgrade   = true

  tags = merge(local.tags, {
    Name = "${local.aurora_cluster_identifier}-instance-${count.index + 1}"
  })
}
