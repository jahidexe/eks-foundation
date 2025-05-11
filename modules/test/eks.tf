module "eks" {
  source = "../eks"

  # Basic Configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  # VPC Configuration - Get values from the VPC module
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  vpc_cidr             = module.vpc.vpc_cidr
  private_subnet_cidrs = module.vpc.private_subnet_cidrs

  # Node Group Configuration
  node_group_instance_types = var.node_group_instance_types
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_group_min_size       = var.node_group_min_size
  node_group_ami_id         = var.node_group_ami_id
  node_group_labels         = var.node_group_labels
  node_group_taints         = var.node_group_taints

  # Cost Optimization Features
  enable_all_logs           = var.enable_all_logs
  use_spot_instances        = var.use_spot_instances
  capacity_type             = var.capacity_type
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  enable_fargate            = var.enable_fargate
  fargate_profiles          = var.fargate_profiles

  # Cluster Schedule
  schedule_cluster_shutdown = var.schedule_cluster_shutdown
  cluster_shutdown_schedule = var.cluster_shutdown_schedule
  cluster_startup_schedule  = var.cluster_startup_schedule

  # Access Management
  manage_aws_auth = var.manage_aws_auth

  # Admin users - hardcoded for simplicity
  eks_admin_users = [
    "arn:aws:iam::509399620336:user/jahid_boss"
  ]

  # Tags
  tags = var.tags
}
