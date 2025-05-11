variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-foundation"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "dev"
}

# These variables are for the VPC module
# In a real scenario, you would have a VPC module output these values
variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
  default     = "vpc-example" # This needs to be replaced with a real VPC ID
}

variable "subnet_ids" {
  description = "Subnets for the EKS cluster (should be private subnets)"
  type        = list(string)
  default     = ["subnet-example1", "subnet-example2"] # These need to be replaced with real subnet IDs
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets where worker nodes will be deployed"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# API Endpoint Access Configuration
variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["81.99.182.203/32"] # Better to specify your corporate CIDR range
}

# Node Group Configuration
variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_ami_id" {
  description = "AMI ID for the node group"
  type        = string
  default     = null # Will use the latest EKS optimized AMI if not specified
}

variable "node_group_labels" {
  description = "Map of labels to apply to the node group"
  type        = map(string)
  default     = {}
}

variable "node_group_taints" {
  description = "List of taints to apply to the node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Cost Optimization Features
variable "enable_all_logs" {
  description = "Enable all cluster log types (increases cost)"
  type        = bool
  default     = false
}

variable "use_spot_instances" {
  description = "Whether to use spot instances for the node group"
  type        = bool
  default     = false
}

variable "capacity_type" {
  description = "Type of capacity for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_cluster_autoscaler" {
  description = "Whether to enable cluster autoscaler"
  type        = bool
  default     = false
}

variable "enable_fargate" {
  description = "Whether to enable Fargate profiles"
  type        = bool
  default     = false
}

variable "fargate_profiles" {
  description = "Map of Fargate profiles to create"
  type = map(object({
    subnet_ids = list(string)
    selectors = list(object({
      namespace = string
      labels    = optional(map(string))
    }))
  }))
  default = {}
}

# Cluster Schedule
variable "schedule_cluster_shutdown" {
  description = "Whether to enable scheduled cluster shutdown"
  type        = bool
  default     = false
}

variable "cluster_shutdown_schedule" {
  description = "Cron expression for cluster shutdown schedule"
  type        = string
  default     = "0 18 ? * MON-FRI *" # Shutdown at 6 PM on weekdays
}

variable "cluster_startup_schedule" {
  description = "Cron expression for cluster startup schedule"
  type        = string
  default     = "0 8 ? * MON-FRI *" # Start at 8 AM on weekdays
}

# Access Management Variables
variable "manage_aws_auth" {
  description = "Whether to manage the aws-auth ConfigMap"
  type        = bool
  default     = false
}

variable "eks_admin_users" {
  description = "List of IAM user ARNs with admin access to the EKS cluster"
  type        = list(string)
  default     = ["arn:aws:iam::509399620336:user/jahid_boss"]
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "EKS-Foundation"
    ManagedBy   = "Terraform"
    Environment = "dev"
    Owner       = "jahid"
  }
}

# Add these missing variables

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "terraform"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-foundation"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Add new variables for encryption and security
variable "kms_key_arn" {
  description = "ARN of the KMS key used for encrypting EKS secrets"
  type        = string
  default     = null # Will create a new KMS key if not specified
}

variable "flow_logs_retention_in_days" {
  description = "Number of days to retain VPC flow logs"
  type        = number
  default     = 14
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in VPC flow logs (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"
}
