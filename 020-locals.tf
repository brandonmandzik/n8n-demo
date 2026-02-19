# Shared local values and computed values

# Core infrastructure locals
locals {
  cluster_name = var.cluster_name
  # TODO: zum rauschmeißen
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "n8n"
  }
}

# Aurora database locals
locals {
  aurora_cluster_identifier = "${local.cluster_name}-aurora"
  aurora_database_name      = "n8n"
  aurora_master_username    = "n8n"
  aurora_subnet_ids         = module.vpc.private_subnets
  eks_cluster_sg_id         = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# Secrets CSI driver locals
locals {
  csi_driver_namespace       = "n8n"
  csi_driver_service_account = "n8n-secrets-sa"
  oidc_provider_url          = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}
