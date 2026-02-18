# =============================================================================
# EKS Cluster Access Management
# =============================================================================
# This file manages who can access the EKS cluster. Add IAM roles/users here
# to grant them cluster admin access automatically via Terraform.
#
# To find your SSO role ARN:
#   aws sts get-caller-identity
#   aws iam get-role --role-name <role-name-from-above>
# =============================================================================

variable "cluster_admins" {
  description = "List of IAM principal ARNs to grant cluster admin access"
  type        = list(string)
  default = [
    # Your SSO admin role - automatically gets cluster admin access
    "arn:aws:iam::401050169397:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_AdministratorAccess_ff32c31a4ad0c2a9",

    # Add additional IAM roles or users here as needed:
    # "arn:aws:iam::401050169397:user/developer-name",
    # "arn:aws:iam::401050169397:role/another-admin-role",
  ]
}

# Create EKS access entries for all cluster admins
resource "aws_eks_access_entry" "admins" {
  for_each = toset(var.cluster_admins)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = local.tags

  depends_on = [aws_eks_cluster.main]
}

# Grant cluster admin policy to all access entries
resource "aws_eks_access_policy_association" "admins" {
  for_each = toset(var.cluster_admins)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admins]
}
