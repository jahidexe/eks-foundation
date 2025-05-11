# EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.subnet_ids

  # Node group scaling configuration
  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  # Node group update configuration
  update_config {
    max_unavailable = 1
  }

  # Node group launch template
  launch_template {
    id      = aws_launch_template.eks_node_group.id
    version = aws_launch_template.eks_node_group.latest_version
  }

  tags = local.node_group_tags
}

# Launch Template for EKS Node Group
resource "aws_launch_template" "eks_node_group" {
  name_prefix   = "${var.cluster_name}-node-group-"
  image_id      = var.node_group_ami_id
  instance_type = var.node_group_instance_types[0]

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_node_group.id]
  }

  user_data = base64encode(local.node_user_data_template)

  tag_specifications {
    resource_type = "instance"
    tags          = local.node_group_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}
