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

  # Set capacity type based on environment
  capacity_type = var.environment == "dev" ? (var.use_spot_instances ? "SPOT" : var.capacity_type) : var.capacity_type

  tags = local.node_group_tags
}

# Launch Template for EKS Node Group
resource "aws_launch_template" "eks_node_group" {
  name_prefix   = "${var.cluster_name}-node-group-"
  image_id      = var.node_group_ami_id
  instance_type = var.environment == "dev" ? (
    length(var.dev_instance_types) > 0 ? var.dev_instance_types[0] : var.node_group_instance_types[0]
  ) : var.node_group_instance_types[0]

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_node_group.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 is required for security
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.environment == "dev" ? var.dev_disk_size : 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn # Use KMS key for EBS volume encryption
    }
  }

  user_data = base64encode(local.node_user_data_template)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.node_group_tags, {
      "aws:eks:cluster-name" = var.cluster_name
      "eks:nodegroup-name"   = "${var.cluster_name}-node-group"
    })
  }

  # Enable detailed monitoring for better insight into node performance
  monitoring {
    enabled = var.environment == "prod" ? true : false
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Implement auto-scaling for node group using AWS Managed Auto Scaling
resource "aws_autoscaling_policy" "cluster_autoscaling" {
  count                  = var.enable_cluster_autoscaler ? 1 : 0
  name                   = "${var.cluster_name}-node-autoscaling-policy"
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
  policy_type            = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0 # Scale when CPU reaches 75% utilization
  }
}
