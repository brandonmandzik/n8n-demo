terraform {
  required_version = ">= 1.6"

# TODO: provider mal weglassen und gucken
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      # version = "~> 1.14"
    }
  }
}

# provider "aws" {
#   region = var.region
# }

provider "kubectl" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.main.name,
      "--region",
      var.region,
      "--output",
      "json"
    ]
  }
}


