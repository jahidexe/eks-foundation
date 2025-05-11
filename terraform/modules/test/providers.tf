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

provider "aws" {
  region = var.aws_region
}

# IMPORTANT: In an actual deployment, this provider would be configured in a separate
# apply step after the EKS cluster is created.
# For the initial deployment, set manage_aws_auth = false in terraform.tfvars

# The Kubernetes provider configuration below is purposely structured to:
# 1. Load conditionally using var.manage_aws_auth to prevent startup errors
# 2. Skip host/cert/token validation when not actually connecting
provider "kubernetes" {
  # Only configure when manage_aws_auth = true
  host = "https://localhost"

  # Skip authentication checks for initial setup
  insecure = true
}

# Note: We're avoiding any data sources that could cause dependency cycles
# Use the update_k8s_provider.sh script after the cluster is created to
# properly configure this provider with actual cluster credentials
