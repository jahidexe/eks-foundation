locals {
  # Basic prefix for all resource names
  prefix = "${var.project_name}-${var.environment}"

  # Simple tags that should be applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }

  # Simple resource names
  names = {
    vpc           = "${local.prefix}-vpc"
    public_subnet = "${local.prefix}-public-subnet"
    private_subnet = "${local.prefix}-private-subnet"
    igw           = "${local.prefix}-igw"
    route_table   = "${local.prefix}-rt"
  }

  # Conditional dependencies for VPC Flow Logs
  flow_log_dependencies = concat(
    var.enable_cloudwatch_logging ? [
      aws_cloudwatch_log_group.vpc_flow_logs[0],
      aws_iam_role.vpc_flow_logs[0]
    ] : [],
    var.enable_s3_logging ? [
      aws_s3_bucket.vpc_flow_logs[0]
    ] : []
  )
} 

resource "aws_flow_log" "this" {
  # ... other configuration ...
  depends_on = local.flow_log_dependencies
} 


