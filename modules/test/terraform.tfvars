# EKS Cluster Configuration
cluster_name    = "eks-foundation"
cluster_version = "1.29"
environment     = "dev"

# Project Information
project_name = "eks-foundation"
owner        = "jahid"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# Node Group Configuration
node_group_instance_types = ["t3.small"]
node_group_desired_size   = 1
node_group_max_size       = 2
node_group_min_size       = 1

# Cost optimization
enable_all_logs    = false
use_spot_instances = false
capacity_type      = "ON_DEMAND"

# For initial deployment, set to false
# After cluster is created, set to true and run terraform apply again
manage_aws_auth = false

tags = {
  Project     = "EKS-Foundation"
  ManagedBy   = "Terraform"
  Environment = "dev"
  Owner       = "jahid"
} 