#!/bin/bash
# This script updates the Kubernetes provider configuration after the EKS cluster is created

# Get the cluster endpoint
CLUSTER_ENDPOINT=$(terraform output -raw module.eks.cluster_endpoint)

# Get the cluster certificate authority
CLUSTER_CA=$(terraform output -raw module.eks.cluster_ca_data)

# Get the cluster name
CLUSTER_NAME=$(terraform output -raw module.eks.cluster_name)

# Update providers.tf file
cat > providers.tf <<EOF
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

# This provider is configured with actual values from the created EKS cluster
provider "kubernetes" {
  host                   = "${CLUSTER_ENDPOINT}"
  cluster_ca_certificate = base64decode("${CLUSTER_CA}")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "${CLUSTER_NAME}"]
    command     = "aws"
  }
}
EOF

# Verify that we have valid cluster information
if [ -z "$CLUSTER_ENDPOINT" ] || [ -z "$CLUSTER_CA" ] || [ -z "$CLUSTER_NAME" ]; then
    echo "Error: Could not retrieve cluster information. Make sure the cluster is created."
    exit 1
fi

# Update terraform.tfvars to enable aws_auth
sed -i '' 's/manage_aws_auth = false/manage_aws_auth = true/g' terraform.tfvars

echo "Kubernetes provider updated. Run 'terraform apply' again to configure aws-auth ConfigMap."
