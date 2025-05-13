locals {
  # Convert simple CIDR lists to the object format if needed
  public_subnets = var.public_subnets != null ? var.public_subnets : [
    for i, cidr in var.public_subnet_cidrs : {
      cidr_block = cidr
      az         = var.availability_zones[i]
    }
  ]

  private_subnets = var.private_subnets != null ? var.private_subnets : [
    for i, cidr in var.private_subnet_cidrs : {
      cidr_block = cidr
      az         = var.availability_zones[i]
    }
  ]

  # Other locals...
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = local.names.vpc
  })
}

# Default Security Group
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  # Explicitly define rules to ensure compliance with security best practices
  # Deny all ingress and egress by default - explicit rules should be created as needed
  
  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-default-sg"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = local.names.igw
  })
}

resource "aws_subnet" "public" {
  # tflint-ignore: CKV_AWS_130
  # This subnet is used for EKS which requires public IP assignment capability
  # for load balancers and control plane access
  count                   = length(local.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index].cidr_block
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = var.map_public_ip_on_launch_public_subnets

  tags = merge(local.common_tags, {
    Name                     = "${local.names.public_subnet}-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(local.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.private_subnets[count.index].cidr_block
  availability_zone       = local.private_subnets[count.index].az
  map_public_ip_on_launch = var.map_public_ip_on_launch_private_subnets

  tags = merge(local.common_tags, {
    Name                              = "${local.names.private_subnet}-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.private_subnets)) : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.names.nat_eip}-${count.index + 1}"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.private_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.names.nat_gateway}-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private Route Table
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.private_subnets)) : 1
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.names.private_route_table}-${count.index + 1}"
  })
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# NAT Gateway Route
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.private_subnets)) : 0
  route_table_id         = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.names.route_table}-public"
  })
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${local.names.vpc}"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.use_kms_encryption ? aws_kms_key.logs[0].arn : null

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs"
  })
}

# KMS Key for encrypting the logs (optional)
resource "aws_kms_key" "logs" {
  count                   = var.use_kms_encryption ? 1 : 0
  description             = "KMS key for encrypting VPC flow logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs-key"
  })
}

# IAM Role for Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${local.names.vpc}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs-role"
  })
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.names.vpc}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs"
  })
}
