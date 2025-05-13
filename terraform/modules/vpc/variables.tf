variable "environment" {
  description = "Environment name for tagging and resource naming"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging and resource naming"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch"
  type        = number
  default     = 14
}

variable "use_kms_encryption" {
  description = "Whether to use KMS encryption for VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in VPC Flow Logs"
  type        = string
  default     = "REJECT"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Traffic type must be one of: ACCEPT, REJECT, ALL"
  }
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

variable "map_public_ip_on_launch_public_subnets" {
  description = "Auto-assign public IP on launch for public subnets. Set to false for better security, allowing explicit control over which instances get public IPs"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch_private_subnets" {
  description = "Auto-assign public IP on launch for private subnets"
  type        = bool
  default     = false
}

# Add these variables to support our test module
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}
