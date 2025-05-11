locals {
  # Basic prefix for all resource names
  prefix = "${var.project_name}-${var.environment}"

  # Simple tags that should be applied to all resources
  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Terraform   = "true"
  }, var.tags)

  # Simple resource names
  names = {
    vpc                 = "${local.prefix}-vpc"
    public_subnet       = "${local.prefix}-public-subnet"
    private_subnet      = "${local.prefix}-private-subnet"
    igw                 = "${local.prefix}-igw"
    route_table         = "${local.prefix}-rt"
    nat_eip             = "${local.prefix}-nat-eip"
    nat_gateway         = "${local.prefix}-nat-gw"
    private_route_table = "${local.prefix}-private-rt"
  }
}
