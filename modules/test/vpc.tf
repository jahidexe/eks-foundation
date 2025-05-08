module "vpc" {
  source = "../vpc"

  # Required variables
  vpc_cidr = "10.0.0.0/16"
  
  # Subnet configurations
  public_subnets = [
    {
      cidr_block = "10.0.1.0/24"
      az         = "us-west-2a"
    },
    {
      cidr_block = "10.0.2.0/24"
      az         = "us-west-2b"
    }
  ]

  private_subnets = [
    {
      cidr_block = "10.0.3.0/24"
      az         = "us-west-2a"
    },
    {
      cidr_block = "10.0.4.0/24"
      az         = "us-west-2b"
    }
  ]

  # NAT Gateway configuration
  enable_nat_gateway   = true
  single_nat_gateway   = true

  # Subnet IP configuration
  map_public_ip_on_launch_public_subnets  = false
  map_public_ip_on_launch_private_subnets = false

  # VPC Flow Logs configuration
  enable_vpc_flow_logs      = false
  enable_cloudwatch_logging = false
  enable_s3_logging         = false

  # S3 bucket configuration
  s3_bucket_force_destroy         = false
  s3_bucket_versioning           = false
  s3_bucket_server_side_encryption = false

  # Common tags
  common_tags = {
    Environment = "test"
    Project     = "eks-test"
    Terraform   = "true"
    Owner       = "DevOps"
  }
}
