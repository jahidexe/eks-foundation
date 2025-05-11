# Configure EKS access with aws-auth ConfigMap
resource "kubernetes_config_map_v1" "aws_auth" {
  count = var.manage_aws_auth ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # Map IAM roles to Kubernetes users - only including node group role
    mapRoles = yamlencode([
      # Node group role - always required
      {
        rolearn  = aws_iam_role.eks_node_group.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    # Map IAM users to Kubernetes users - only admin users
    mapUsers = yamlencode([
      for user_arn in var.eks_admin_users : {
        userarn  = user_arn
        username = "admin:${element(split("/", user_arn), 1)}"
        groups   = ["system:masters"]
      }
    ])
  }

  # Wait until after cluster and node group creation
  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]

  # To avoid dependency cycles, we explicitly ignore changes to mapRoles after creation
  lifecycle {
    ignore_changes = [
      data["mapRoles"]
    ]
  }
}

# Remove the developer namespace, roles and role bindings since we're simplifying
