# Kubernetes resources for CSI Driver integration
# Managed by Terraform using kubectl provider - ARNs flow automatically from AWS resources

# Create n8n namespace
resource "kubectl_manifest" "n8n_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: n8n
  YAML
}

# ServiceAccount with IRSA annotation
resource "kubectl_manifest" "n8n_service_account" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "n8n-secrets-sa"
      namespace = "n8n"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.secrets_csi.arn
      }
    }
  })

  depends_on = [
    aws_iam_role.secrets_csi,
    aws_eks_addon.secrets_store_csi_driver,
    kubectl_manifest.n8n_namespace
  ]
}

# SecretProviderClass for Aurora credentials
resource "kubectl_manifest" "aurora_secret_provider" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "n8n-aurora-secrets-provider"
      namespace = "n8n"
    }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([{
          objectName = aws_secretsmanager_secret.aurora_credentials.arn
          objectType = "secretsmanager"
          jmesPath = [
            { path = "username", objectAlias = "db-username" },
            { path = "password", objectAlias = "db-password" },
            { path = "host", objectAlias = "db-host" },
            { path = "port", objectAlias = "db-port" },
            { path = "dbname", objectAlias = "db-name" }
          ]
        }])
      }
      secretObjects = [{
        secretName = "n8n-aurora-secrets"
        type       = "Opaque"
        data = [
          { objectName = "db-username", key = "DB_POSTGRESDB_USER" },
          { objectName = "db-password", key = "DB_POSTGRESDB_PASSWORD" },
          { objectName = "db-host", key = "DB_POSTGRESDB_HOST" },
          { objectName = "db-port", key = "DB_POSTGRESDB_PORT" },
          { objectName = "db-name", key = "DB_POSTGRESDB_DATABASE" }
        ]
      }]
    }
  })

  depends_on = [kubectl_manifest.n8n_service_account]
}

# ClusterRole for CSI driver to manage Kubernetes secrets (missing from EKS add-on)
resource "kubectl_manifest" "csi_driver_secrets_role" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: secrets-store-csi-driver-secrets
      labels:
        app: secrets-store-csi-driver
    rules:
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["create", "get", "update", "patch", "list", "watch"]
  YAML

  depends_on = [aws_eks_addon.secrets_store_csi_driver]
}

# Bind secrets role to CSI driver service account
resource "kubectl_manifest" "csi_driver_secrets_rolebinding" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: secrets-store-csi-driver-secrets
      labels:
        app: secrets-store-csi-driver
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: secrets-store-csi-driver-secrets
    subjects:
    - kind: ServiceAccount
      name: secrets-store-csi-driver
      namespace: aws-secrets-manager
  YAML

  depends_on = [kubectl_manifest.csi_driver_secrets_role]
}
