# =============================================================================
# Kubernetes Manifests Deployment
# =============================================================================
# Automatically applies Kubernetes manifests from ./k8s directory after
# the EKS cluster and all dependencies are ready.
#
# IMPORTANT: This applies AFTER Terraform kubectl provider resources in
# 500-kubernetes.tf to avoid conflicts and ensure proper ordering.
# =============================================================================

resource "null_resource" "apply_kubernetes_manifests" {
  # Trigger re-deployment when k8s files change
  triggers = {
    cluster_endpoint = aws_eks_cluster.main.endpoint
    # Force re-run if any k8s files change
    manifests_hash = sha256(join("", [for f in fileset("${path.module}/k8s", "**/*.yaml") : filesha256("${path.module}/k8s/${f}")]))
  }

  # CRITICAL: Ensure ALL dependencies are ready before deploying
  depends_on = [
    # Cluster must be fully created
    aws_eks_cluster.main,

    # Access entries must be configured (for kubectl authentication)
    aws_eks_access_entry.admins,
    aws_eks_access_policy_association.admins,

    # ALL critical addons must be ready
    aws_eks_addon.vpc_cni,           # Networking
    aws_eks_addon.coredns,           # DNS resolution
    aws_eks_addon.kube_proxy,        # Service networking
    aws_eks_addon.ebs_csi,           # CRITICAL: Required for StorageClass
    aws_eks_addon.metrics_server,    # Required for HPA (horizontal pod autoscaler)
    aws_eks_addon.secrets_store_csi_driver,  # Required for secrets management

    # Terraform-managed K8s resources must be applied first
    kubectl_manifest.n8n_namespace,              # Namespace
    kubectl_manifest.n8n_service_account,        # ServiceAccount with IRSA
    kubectl_manifest.aurora_secret_provider,     # SecretProviderClass
    kubectl_manifest.csi_driver_secrets_role,    # RBAC for CSI driver
    kubectl_manifest.csi_driver_secrets_rolebinding,
  ]

  # Apply Kubernetes manifests
  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating kubeconfig..."
      aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.region}

      echo "Waiting for cluster to be ready..."
      kubectl wait --for=condition=Ready nodes --all --timeout=300s || echo "Nodes not ready yet, continuing anyway..."

      echo "Applying Kubernetes manifests..."
      kubectl apply -f ./k8s --recursive

      echo "Kubernetes deployment complete!"
    EOT
  }

  # Cleanup on destroy (optional - remove if you want to keep resources)
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up Kubernetes resources..."
      kubectl delete -f ./k8s --recursive --ignore-not-found=true || echo "Cleanup complete or resources already removed"
    EOT
  }
}

# Output deployment status
output "kubernetes_deployment_status" {
  description = "Status of Kubernetes manifests deployment"
  value       = "Kubernetes manifests from ./k8s have been applied to cluster ${aws_eks_cluster.main.name}"
  depends_on  = [null_resource.apply_kubernetes_manifests]
}
