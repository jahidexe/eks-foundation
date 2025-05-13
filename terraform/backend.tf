terraform {
  backend "s3" {
    # These values will be filled via the CI/CD pipeline
    # Do not hardcode values here as they will be provided via:
    # terraform init -backend-config=...
    # Region: eu-west-1 (Ireland)
  }
} 