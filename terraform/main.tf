provider "aws" {
  region = "eu-west-1"
}

locals {
  project     = "eks-foundation"
  environment = "dev"
  region      = "eu-west-1"
  
  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# Use the VPC module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name             = "${local.project}-${local.environment}-vpc"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = true
  
  tags = local.tags
}

# Output VPC information
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
} 