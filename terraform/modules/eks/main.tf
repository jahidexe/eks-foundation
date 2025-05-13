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
    ] : var.environment == "dev" && var.minimal_logs ? [
    "api",
    "audit",
    "authenticator",
    ] : [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access && length(var.public_access_cidrs) > 0 ? var.public_access_cidrs : []
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  tags = local.cluster_tags

  # This prevents destruction of the cluster
  lifecycle {
    # Note: For production clusters, set prevent_destroy to true in a separate configuration
    prevent_destroy = false
  }
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

# Auto shutdown for dev environments to reduce costs
resource "aws_autoscaling_schedule" "scale_down" {
  count                  = var.environment == "dev" && var.schedule_cluster_shutdown ? 1 : 0
  scheduled_action_name  = "${var.cluster_name}-scale-down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = var.cluster_shutdown_schedule
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
}

resource "aws_autoscaling_schedule" "scale_up" {
  count                  = var.environment == "dev" && var.schedule_cluster_shutdown ? 1 : 0
  scheduled_action_name  = "${var.cluster_name}-scale-up"
  min_size               = var.node_group_min_size
  max_size               = var.node_group_max_size
  desired_capacity       = var.node_group_desired_size
  recurrence             = var.cluster_startup_schedule
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.environment == "prod" ? 90 : var.environment == "dev" ? 14 : 30
  kms_key_id        = aws_kms_key.eks.arn

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-eks-cloudwatch-log-group"
  })
}

# Free Tier Cost Optimization - Use t2.micro for EKS nodes if free_tier_eligible is true
resource "null_resource" "free_tier_warning" {
  count = var.free_tier_eligible ? 1 : 0

  # This resource does nothing but provides a warning message during plan/apply
  provisioner "local-exec" {
    command = "echo 'WARNING: EKS control plane ($0.10/hour) is not free tier eligible. Only worker nodes are being optimized.'"
  }
}

# EKS Add-ons - Configure the base functionality for security and cost optimization
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  configuration_values = var.enable_vpc_cni_prefix_delegation ? jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  }) : null

  tags = merge(local.common_tags, {
    "eks-addon" = "vpc-cni"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  tags = merge(local.common_tags, {
    "eks-addon" = "coredns"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  tags = merge(local.common_tags, {
    "eks-addon" = "kube-proxy"
  })
}
