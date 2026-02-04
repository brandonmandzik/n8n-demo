# EKS Cluster with Auto Mode
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = module.vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Auto Mode configuration
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.node.arn
  }

  # Auto Mode networking
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  # Auto Mode storage
  storage_config {
    block_storage {
      enabled = true
    }
  }

  # Required for Auto Mode
  bootstrap_self_managed_addons = false

  # Access configuration for Auto Mode
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}
