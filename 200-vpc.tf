# VPC using community module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # name = "${local.cluster_name}-vpc"
  name = local._name_tag
  cidr = var.vpc_cidr

  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]
  # Dynamic subnet calculation from VPC CIDR
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),   # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),   # 10.0.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3),   # 10.0.3.0/24
  ]
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 101), # 10.0.101.0/24
    cidrsubnet(var.vpc_cidr, 8, 102), # 10.0.102.0/24
    cidrsubnet(var.vpc_cidr, 8, 103), # 10.0.103.0/24
  ]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true # HA: One NAT Gateway per AZ

  # EKS tags for subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
