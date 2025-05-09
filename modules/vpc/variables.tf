variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet configurations"
  type = list(object({
    cidr_block = string
    az         = string
  }))
}

variable "private_subnets" {
  description = "List of private subnet configurations"
  type = list(object({
    cidr_block = string # The IPv4 CIDR block for the subnet
    az         = string # The Availability Zone for the subnet
  }))
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all private subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encrypting CloudWatch Log Group"
  type        = string
  default     = null
}

variable "enable_s3_logging" {
  description = "Enable S3 logging for VPC Flow Logs"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for VPC Flow Logs"
  type        = string
  default     = null
}

variable "s3_bucket_force_destroy" {
  description = "Force destroy the S3 bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "s3_bucket_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_server_side_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch_public_subnets" {
  description = "Auto-assign public IP on launch for public subnets"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch_private_subnets" {
  description = "Auto-assign public IP on launch for private subnets"
  type        = bool
  default     = false
}
