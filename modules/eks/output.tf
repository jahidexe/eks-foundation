output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_group_security_group_id" {
  description = "Security group ID attached to the EKS node group"
  value       = aws_security_group.eks_node_group.id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.this.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for cluster encryption"
  value       = aws_kms_key.eks.arn
}

# IAM Role Information
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster (created internally)"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster (created internally)"
  value       = aws_iam_role.eks_cluster.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group (created internally)"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node group (created internally)"
  value       = aws_iam_role.eks_node_group.name
}

# Access Configuration
output "aws_auth_config_map" {
  description = "The aws-auth ConfigMap for cluster access"
  value       = var.manage_aws_auth ? kubernetes_config_map_v1.aws_auth[0].data : null
  depends_on  = [kubernetes_config_map_v1.aws_auth]
  sensitive   = true
}

output "cluster_ca_data" {
  description = "The base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
