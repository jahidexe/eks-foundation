terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "myproject-dev-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "myproject-dev-terraform-locks"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-1:509399620336:key/99e51278-2f41-4b52-88f5-ef5db7d5fe94"
  }
}

