# Core Configuration Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
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
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Networking Variables
variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the EKS cluster (should be private subnets)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets where worker nodes will be deployed"
  type        = list(string)
}

# Cluster Endpoint Access Configuration
variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint when public access is enabled"
  type        = list(string)
  default     = []
}

# Logging and Encryption
variable "enable_all_logs" {
  description = "Enable all cluster log types (increases cost)"
  type        = bool
  default     = false
}

variable "minimal_logs" {
  description = "Use minimal but compliant logging setup (for dev environments)"
  type        = bool
  default     = false
}

# Node Group Configuration
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

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

# Cost Optimization for Dev Environments
variable "dev_instance_types" {
  description = "List of instance types for dev environments (cost optimized)"
  type        = list(string)
  default     = ["t3.micro"] # Free tier eligible
}

variable "dev_disk_size" {
  description = "EBS volume size for dev environments (GB)"
  type        = number
  default     = 10
}

variable "node_group_ami_id" {
  description = "AMI ID for the node group"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Amazon EKS-optimized AMI for Amazon Linux 2
}

variable "capacity_type" {
  description = "Type of capacity for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT"
  }
}

variable "use_spot_instances" {
  description = "Whether to use spot instances for the node group"
  type        = bool
  default     = false
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

variable "node_group_labels" {
  description = "Map of labels to apply to the node group"
  type        = map(string)
  default     = {}
}

# Feature Flags
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

# Cost Management
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

# Free Tier Optimization Configuration
variable "free_tier_eligible" {
  description = "Whether to optimize for AWS Free Tier eligibility"
  type        = bool
  default     = false
}

variable "free_tier_instance_type" {
  description = "Instance type eligible for AWS Free Tier"
  type        = string
  default     = "t2.micro" # AWS Free Tier eligible
}

variable "cost_optimized_ebs_type" {
  description = "EBS volume type optimized for cost"
  type        = string
  default     = "gp3" # More cost-effective than gp2
}

# Enhanced Security
variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for increased pod density"
  type        = bool
  default     = false
}

variable "enable_security_groups_for_pods" {
  description = "Enable security groups for pods"
  type        = bool
  default     = false
}

variable "enable_secrets_encryption" {
  description = "Enable encryption of Kubernetes secrets using KMS"
  type        = bool
  default     = true
}

variable "enable_imdsv2" {
  description = "Enforce IMDSv2 for EC2 instances (enhanced security)"
  type        = bool
  default     = true
}

# Access Configuration
variable "eks_admin_users" {
  description = "List of IAM user ARNs with admin access to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "manage_aws_auth" {
  description = "Whether to manage the aws-auth ConfigMap"
  type        = bool
  default     = false
}
