terraform {
  backend "local" {
    # Local backend for testing
    # To use S3 backend, comment out the local backend and uncomment the S3 backend configuration below
    # Make sure to set the required GitHub secrets or provide values directly
  }

  # backend "s3" {
  #   bucket       = "your-terraform-state-bucket"  # Or use GitHub secrets: ${{ secrets.TF_STATE_BUCKET }}
  #   key          = "terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   kms_key_id   = "arn:aws:kms:eu-west-1:509399620336:key/99e51278-2f41-4b52-88f5-ef5db7d5fe94"
  #   use_lockfile = true  # For Terraform >= 1.6.x
  # }
}
