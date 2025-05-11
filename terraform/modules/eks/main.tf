resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  enabled_cluster_log_types = var.enable_all_logs ? [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
    ] : [
    "api",
    "audit"
  ]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : []
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  tags = local.cluster_tags
}

# Get current AWS region
data "aws_region" "current" {}

# Create IAM OIDC provider for the cluster
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = local.oidc_provider_tags
}
