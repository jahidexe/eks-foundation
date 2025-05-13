terraform {
  backend "s3" {
    bucket       = "myproject-dev-terraform-state"
    key          = "terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:eu-west-1:509399620336:key/99e51278-2f41-4b52-88f5-ef5db7d5fe94"
    use_lockfile = true
  }
}
