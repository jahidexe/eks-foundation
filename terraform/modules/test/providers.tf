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

# For the initial deployment, the Kubernetes provider is not required
# After cluster creation, uncomment this and set manage_aws_auth = true in terraform.tfvars
# 
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this[0].endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#     command     = "aws"
#   }
# }
# 
# data "aws_eks_cluster" "this" {
#   count = var.manage_aws_auth ? 1 : 0
#   name  = var.cluster_name
#   depends_on = [
#     module.eks
#   ]
# }

# Note: After the cluster is created, you can run:
# 1. Set manage_aws_auth = true in terraform.tfvars
# 2. Uncomment the provider "kubernetes" block above
# 3. Run terraform apply again
