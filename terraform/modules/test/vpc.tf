# Simple VPC module for testing
# In a real scenario, you would use the AWS VPC module or a custom VPC module

module "vpc" {
  source = "../vpc"

  # Required variables
  vpc_cidr     = var.vpc_cidr
  project      = var.project_name
  owner        = var.owner
  environment  = var.environment
  cluster_name = var.cluster_name

  # Define public_subnets and private_subnets as required by the module
  public_subnets = [
    for i, cidr in var.public_subnet_cidrs : {
      cidr_block = cidr
      az         = var.availability_zones[i]
    }
  ]

  private_subnets = [
    for i, cidr in var.private_subnet_cidrs : {
      cidr_block = cidr
      az         = var.availability_zones[i]
    }
  ]

  # These are still needed for the module's internal logic
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  # Optional configuration with defaults
  enable_nat_gateway = true
  single_nat_gateway = true # Use single NAT for cost savings

  # Security settings - explicitly set to false for public subnets
  map_public_ip_on_launch_public_subnets  = false
  map_public_ip_on_launch_private_subnets = false

  # Flow logs - enable for security
  enable_vpc_flow_logs      = true
  flow_logs_retention_days  = 14
  flow_logs_traffic_type    = "ALL"

  # Pass through tags
  tags = var.tags
}
