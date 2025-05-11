terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The Kubernetes provider configuration should be handled in the root module
# This ensures that the module can be instantiated without requiring immediate access to the cluster
# The module just defines which providers it needs, but lets the root module configure them
