# =============================================================================
# Lean Outputs - Focused on Access & Configuration
# =============================================================================

# Basic cluster info
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

# Configuration commands
output "configure_kubectl" {
  description = "Command to configure kubectl access"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.region}"
}

output "get_n8n_url" {
  description = "Command to get n8n application URL"
  value       = "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

# Quick start guide
output "quick_start" {
  description = "Quick start guide to access n8n"
  value       = <<-EOT
    ╔══════════════════════════════════════════════════════════════╗
    ║  n8n Deployment Complete - Quick Start Guide                 ║
    ╚══════════════════════════════════════════════════════════════╝

    1. Configure kubectl:
       ${join(" ", [
         "aws eks update-kubeconfig",
         "--name ${aws_eks_cluster.main.name}",
         "--region ${var.region}"
       ])}

    2. Get n8n application URL (wait ~2 min if just deployed):
       kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

    3. Access n8n:
       Visit: http://<url-from-step-2>

    Note: Database credentials are automatically injected via AWS Secrets Manager
  EOT
}
