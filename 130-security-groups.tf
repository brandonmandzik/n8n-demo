# Security group for Aurora cluster
resource "aws_security_group" "aurora" {
  # TODO: name
  name_prefix = "${local.aurora_cluster_identifier}-"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    # Name = "${local.aurora_cluster_identifier}-sg"
    Name = local._name_tag
  })
}

# Allow inbound PostgreSQL from EKS cluster security group
resource "aws_security_group_rule" "aurora_ingress_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = local.eks_cluster_sg_id
  security_group_id        = aws_security_group.aurora.id
  description              = "Allow PostgreSQL access from EKS cluster"
}

# Allow egress within VPC only (Aurora doesn't need internet access)
resource "aws_security_group_rule" "aurora_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.aurora.id
  description       = "Allow outbound traffic within VPC only"
}
