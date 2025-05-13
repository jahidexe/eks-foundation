# EKS Foundation Terraform Infrastructure

This directory contains Terraform code to create AWS infrastructure for the EKS Foundation project.

## Prerequisites

- AWS credentials with appropriate permissions
- Terraform installed locally (for manual deployments)
- S3 bucket and DynamoDB table for Terraform state (details below)

## Repository Structure

```
terraform/
├── backend.tf         # S3 backend configuration
├── main.tf            # Main Terraform configuration
├── modules/           # Reusable Terraform modules
│   ├── eks/           # EKS cluster module
│   ├── vpc/           # VPC module
│   └── test/          # Test configurations
└── README.md          # This file
```

## GitHub Actions CI/CD

This project uses GitHub Actions for CI/CD. The workflow:

1. Runs on changes to files in the `terraform/` directory
2. Uses S3 for remote state management
3. Formats, validates, plans, and applies Terraform code

### Required GitHub Secrets

Set up the following secrets in your GitHub repository settings:

- `JAHID_GITHUB_CI_ACCESS_KEY_ID`: AWS access key ID
- `JAHID_GITHUB_CI_SECRET_KEY_ID`: AWS secret access key
- `TF_STATE_BUCKET`: Name of the S3 bucket for Terraform state
- `TF_LOCK_TABLE`: Name of the DynamoDB table for state locking

## Setting Up the Backend Infrastructure

Before the first Terraform run, you need to create the backend infrastructure:

1. Create an S3 bucket for Terraform state
2. Enable versioning on the bucket
3. Enable server-side encryption (preferably with KMS)
4. Create a DynamoDB table for state locking
5. Set up appropriate IAM permissions

You can create these manually or use the AWS CLI to set them up.

## Local Development

To run Terraform locally:

```bash
# Initialize with remote backend
terraform init \
  -backend-config="bucket=YOUR_BUCKET_NAME" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=YOUR_DYNAMODB_TABLE" \
  -backend-config="encrypt=true"

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Create execution plan
terraform plan

# Apply changes
terraform apply
``` 