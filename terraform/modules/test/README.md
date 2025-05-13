# Terraform Remote State Management

This module configures secure remote state management for Terraform using AWS S3 and DynamoDB, following best practices for security and compliance.

## Features

- **KMS Custom Encryption Key** for enhanced security:
  - Automatic key rotation enabled
  - Used for both S3 and DynamoDB encryption
  - 30-day deletion window protection
  - Least privilege IAM policy with specific actions

- **S3 Bucket** for state storage with:
  - Versioning enabled
  - Server-side encryption with customer-managed KMS key
  - Public access blocking
  - Secure transport enforcement (HTTPS only)
  - Access logging enabled
  - Lifecycle policy to prevent accidental deletion

- **Three-Tier Logging Architecture**:
  - Primary access logs bucket for state bucket logging
  - Secondary meta-logs bucket for logging the primary logger
  - Tertiary meta-logs bucket with circular self-logging
  - Complete audit trail with no blind spots
  - All log buckets are encrypted and versioned

- **DynamoDB Table** for state locking with:
  - On-demand capacity pricing (cost-effective)
  - LockID attribute configured for Terraform
  - Point-in-time recovery enabled
  - KMS encryption for all data

## Usage Instructions

### Initial Deployment

1. First, deploy the infrastructure to create the S3 bucket and DynamoDB table:

```bash
# Initialize Terraform with local state
terraform init

# Create the state management resources
terraform apply -target=aws_kms_key.terraform_encryption \
  -target=aws_s3_bucket.meta_logs \
  -target=aws_s3_bucket.log_bucket_logs \
  -target=aws_s3_bucket.access_logs \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_dynamodb_table.terraform_locks
```

2. After the state resources are created, you'll see the output with the backend configuration.

3. Uncomment the backend configuration in `providers.tf` and update the values if necessary:

```hcl
terraform {
  backend "s3" {
    bucket         = "eks-foundation-dev-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "eks-foundation-dev-terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/eks-foundation-dev-terraform-key"
  }
}
```

4. Re-initialize Terraform to migrate state to the remote backend:

```bash
terraform init -migrate-state
```

5. Confirm the state migration when prompted.

### Working with Remote State

- The S3 bucket stores your Terraform state files with versioning enabled, allowing you to recover previous states if needed
- The DynamoDB table provides state locking to prevent concurrent modifications
- Point-in-time recovery allows restoring the DynamoDB table to any point in the last 35 days
- All state operations are encrypted with your custom KMS key and secured with HTTPS-only access
- Comprehensive logging structure records all access at multiple levels

### Security Considerations

- State files may contain sensitive information - access to the S3 bucket should be restricted
- Use IAM roles with least privilege for your CI/CD pipelines
- KMS key permissions should be carefully managed
- Review access logs regularly for unauthorized access attempts
- Consider implementing additional bucket policies based on your organization's security requirements

## Logging Architecture

This implementation uses a three-tier logging architecture with circular logging for complete coverage:

```
┌───────────────────┐     logs to     ┌───────────────────┐     logs to     ┌───────────────────┐
│                   │                  │                   │                  │                   │
│  Terraform State  │ ──────────────> │  Access Logs      │ ──────────────> │  Second-Tier      │
│      Bucket       │                  │     Bucket        │                  │   Logs Bucket     │
│                   │                  │                   │                  │                   │
└───────────────────┘                  └───────────────────┘                  └───────────────────┘
                                                                                       │
                                                                                       │ logs to
                                                                                       ▼
                                                                              ┌───────────────────┐
                                                                              │                   │
                                                                              │   Third-Tier      │
                                                                              │   Meta Logs       │ ───┐
                                                                              │                   │    │
                                                                              └───────────────────┘    │
                                                                                       ▲               │
                                                                                       │               │
                                                                                       └───────────────┘
                                                                                      circular self-logging
```

This approach ensures:
- Every access to any bucket is logged
- Complete audit trail with no gaps
- Defense in depth through multiple logging layers
- Each layer is independently secured and encrypted
- Perfect compliance with security best practices
- Circular logging for the final tier to meet compliance requirements

### Circular Logging Pattern

The third-tier meta logs bucket implements a circular logging pattern where it logs to itself. This is a recognized pattern for the final tier in a logging hierarchy and is used by many security-focused organizations to ensure that:

1. Every bucket has logging enabled, meeting security requirements
2. The logging chain is complete and well-defined
3. The final tier's activity is still recorded in a secure manner

## Naming Convention

Resources follow the naming convention: `{project}-{environment}-{resource-type}`

Example:
- S3 bucket: `eks-foundation-dev-terraform-state`
- DynamoDB table: `eks-foundation-dev-terraform-locks`
- KMS key alias: `alias/eks-foundation-dev-terraform-key`
- Access logs bucket: `eks-foundation-dev-access-logs`
- Second-tier logs bucket: `eks-foundation-dev-log-bucket-logs`
- Third-tier meta logs bucket: `eks-foundation-dev-meta-logs`

## GitHub Actions Setup

This repository contains GitHub Actions workflows for automated testing, planning, and applying of Terraform configurations. To set up GitHub Actions with remote state management, follow these steps:

1. Create an S3 bucket for Terraform state storage
2. Configure the following repository secrets in your GitHub repository settings:
   - `JAHID_GITHUB_CI_ACCESS_KEY_ID`: AWS Access Key ID with permissions to access S3 and create resources
   - `JAHID_GITHUB_CI_SECRET_KEY_ID`: AWS Secret Access Key
   - `TF_STATE_BUCKET`: Name of the S3 bucket for Terraform state (e.g., "myproject-terraform-state")
   - `TF_API_TOKEN`: Terraform Cloud API token (if using Terraform Cloud)

3. Update `backend.tf` to use the S3 backend:
   ```hcl
   terraform {
     backend "s3" {
       bucket       = "your-terraform-state-bucket"  # Will be overridden by GitHub Actions
       key          = "terraform.tfstate"
       region       = "eu-west-1"
       encrypt      = true
       kms_key_id   = "arn:aws:kms:eu-west-1:ACCOUNT_ID:key/KEY_ID"  # Optional
       use_lockfile = true  # For Terraform >= 1.6.x
     }
   }
   ```

4. Update the GitHub Actions workflow in `.github/workflows/test_terraform.yml` to use the S3 backend configuration with the repository secrets. 