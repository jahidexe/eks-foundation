# EKS Terraform Module

This module deploys an Amazon EKS cluster with configurable options for both cost-optimized development environments and production-grade deployments.

## Features

- **Environment-aware configuration**: Different defaults for dev, test, and prod environments
- **Cost optimization tools**: Scheduled shutdowns, spot instances, and minimal resource allocation
- **Production-ready options**: High availability, security, and compliance settings
- **Flexible node groups**: Configurable instance types, scaling, and capacity types
- **Security compliance**: Proper logging, encryption, and network isolation

## Usage

### Cost-Optimized Development Environment

```hcl
module "eks_dev" {
  source = "../modules/eks"

  # Basic Configuration
  cluster_name    = "dev-cluster"
  cluster_version = "1.29"
  environment     = "dev"  # Sets appropriate defaults for dev

  # VPC Configuration (required)
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  vpc_cidr             = module.vpc.vpc_cidr
  private_subnet_cidrs = module.vpc.private_subnet_cidrs

  # Cost Optimization Settings
  use_spot_instances        = true                # Use cheaper spot instances
  dev_instance_types        = ["t3.micro"]        # Smaller, cheaper instances
  dev_disk_size             = 10                  # Smaller disk size
  schedule_cluster_shutdown = true                # Auto-shutdown during off-hours
  cluster_shutdown_schedule = "0 18 ? * MON-FRI *" # Turn off at 6 PM weekdays
  cluster_startup_schedule  = "0 8 ? * MON-FRI *"  # Turn on at 8 AM weekdays
  minimal_logs              = true                # Use minimal but compliant logging

  # Development-appropriate scaling
  node_group_desired_size   = 1
  node_group_max_size       = 2
  node_group_min_size       = 0  # Can scale to zero during low usage

  # For easier access during development
  endpoint_public_access    = true
  public_access_cidrs       = ["YOUR_IP_ADDRESS/32"]  # Restrict to your IP

  # Tags
  tags = {
    Environment = "Development"
    Project     = "EKS-Testing"
    ManagedBy   = "Terraform"
  }
}
```

### Production-Grade Environment

```hcl
module "eks_prod" {
  source = "../modules/eks"

  # Basic Configuration
  cluster_name    = "prod-cluster"
  cluster_version = "1.29"
  environment     = "prod"  # Sets appropriate defaults for production

  # VPC Configuration (required)
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  vpc_cidr             = module.vpc.vpc_cidr
  private_subnet_cidrs = module.vpc.private_subnet_cidrs

  # Production-grade node configuration
  node_group_instance_types = ["t3.medium"]     # More capable instances
  node_group_desired_size   = 2                 # At least 2 nodes for high availability
  node_group_max_size       = 5                 # Room to scale up
  node_group_min_size       = 2                 # Always maintain redundancy

  # Reliability settings
  use_spot_instances        = false
  capacity_type             = "ON_DEMAND"       # More reliable than spot
  
  # Enhanced logging and monitoring
  enable_all_logs           = true              # Full audit trail and monitoring
  
  # Security settings
  endpoint_public_access    = false             # Private API endpoint only
  endpoint_private_access   = true              # Access via VPN/bastion
  
  # Production features
  enable_cluster_autoscaler = true              # Auto-scale based on demand
  
  # Admin access configuration
  manage_aws_auth           = true
  eks_admin_users           = ["arn:aws:iam::123456789012:user/admin"]
  
  # Tags
  tags = {
    Environment = "Production"
    CostCenter  = "Operations"
    ManagedBy   = "Terraform"
    Criticality = "High"
  }
}
```

## Cost Optimization Strategies

This module implements several approaches to reduce EKS costs in development environments:

1. **Automatic shutdown scheduling**: Reduces run time from 168 hours/week to 40 hours/week (76% savings)
2. **Spot instances**: Can provide up to 90% discount compared to on-demand prices
3. **Minimal instance sizing**: Using t3.micro instances instead of larger instances
4. **Reduced storage**: Smaller EBS volumes (10GB vs 20GB)
5. **Compliant minimal logging**: Only enabling required log types while maintaining compliance
6. **Elastic scaling**: Allowing node count to drop to zero during scheduled off-hours

For a typical development cluster, these optimizations can reduce costs by 70-85% compared to a standard deployment.

## Essential Variables

| Variable | Description | Dev Default | Prod Default |
|----------|-------------|------------|--------------|
| `environment` | Environment type (dev, test, prod) | `"dev"` | `"prod"` |
| `use_spot_instances` | Whether to use spot instances | `true` (recommended for dev) | `false` (on-demand for reliability) |
| `dev_instance_types` | Instance types for dev env | `["t3.micro"]` | n/a (uses `node_group_instance_types`) |
| `node_group_instance_types` | Primary instance types | `["t3.small"]` | `["t3.medium"]` or larger |
| `schedule_cluster_shutdown` | Enable auto-shutdown | `true` for dev | `false` for prod |
| `minimal_logs` | Use minimal but compliant logging | `true` for dev | n/a (use `enable_all_logs`) |
| `enable_all_logs` | Enable all logging types | `false` for dev | `true` for prod |
| `endpoint_public_access` | Allow public API access | Optional for dev | `false` for prod |

## Security Compliance

This module ensures that all EKS clusters meet security requirements:

- Complete control plane logging is enabled for all environments, including:
  - API server logs
  - Audit logs 
  - Authenticator logs
  - Controller manager logs
  - Scheduler logs
- Cluster secrets are encrypted at rest using KMS
- API server endpoint can be restricted to private access
- Network security groups limit access to the cluster
- IAM roles follow the principle of least privilege
- OIDC provider integration for service account authentication

### VPC Security Features

The accompanying VPC module includes important security features:

- **VPC Flow Logs**: Captures network traffic information for security monitoring and incident response
- **CloudWatch Integration**: Flow logs are sent to CloudWatch for analysis and retention
- **KMS Encryption**: Log data is encrypted at rest (optional but recommended)
- **Log Retention**: Configurable retention period (default: 14 days)
- **Least Privilege IAM**: Fine-grained IAM policies that follow security best practices:
  - Specific resources are defined for each permission
  - No wildcard permissions for sensitive IAM actions
  - Separate permissions for log group creation, log stream creation, and log event submissions

These network security features are essential for production environments and are recommended even for development to maintain security visibility.

## Maintenance and Operations

### Upgrading the Cluster

To upgrade a cluster's Kubernetes version:

1. Update the `cluster_version` variable
2. Apply the changes with sufficient testing in lower environments first
3. Monitor the cluster during and after the upgrade

### Monitoring Costs

For development environments with cost optimization enabled:

1. Set up AWS Cost Explorer with tags for tracking
2. Add alerts for unexpected cost increases
3. Regularly review if scheduled shutdowns are functioning correctly
4. Consider complete teardown of development clusters when not in use for extended periods

### Security Monitoring

For effective security monitoring:

1. Set up CloudWatch Alarms or third-party tools to monitor VPC flow logs for suspicious activity
2. Review access patterns in cluster logs regularly
3. Implement automated scanning of container images and running workloads
4. Configure GuardDuty for additional AWS security monitoring

### Best Practices

1. Use proper tagging for cost allocation
2. Review and adjust scaling parameters based on actual workload
3. Regularly update to the latest supported Kubernetes version
4. Apply security patches promptly
5. Implement infrastructure as code for all changes 