resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = local.names.vpc
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index].cidr_block
  availability_zone       = var.public_subnets[count.index].az
  map_public_ip_on_launch = var.map_public_ip_on_launch_public_subnets

  tags = merge(local.common_tags, {
    Name                     = "${local.names.public_subnet}-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnets[count.index].cidr_block
  availability_zone       = var.private_subnets[count.index].az
  map_public_ip_on_launch = var.map_public_ip_on_launch_private_subnets

  tags = merge(local.common_tags, {
    Name                              = "${local.names.private_subnet}-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.names.nat_eip}-${count.index + 1}"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.names.nat_gateway}-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private Route Table
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 1
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.names.private_route_table}-${count.index + 1}"
  })
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# NAT Gateway Route
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  route_table_id         = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs && var.enable_cloudwatch_logging ? 1 : 0
  name              = coalesce(var.log_group_name, "${local.names.vpc}-flow-logs")
  retention_in_days = 30
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs"
  })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs && var.enable_cloudwatch_logging ? 1 : 0
  name  = "${local.names.vpc}-flow-logs-role"

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

# IAM Role Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs && var.enable_cloudwatch_logging ? 1 : 0
  name  = "${local.names.vpc}-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.vpc_flow_logs[0].arn,
          "${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"
        ]
      }
    ]
  })
}

# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  count         = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket        = coalesce(var.s3_bucket_name, "${local.names.vpc}-flow-logs-${data.aws_caller_identity.current.account_id}")
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs-bucket"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging && var.s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging && var.s3_bucket_server_side_encryption ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy for VPC Flow Logs
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.vpc_flow_logs[0].arn}/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl"
        ]
        Resource = aws_s3_bucket.vpc_flow_logs[0].arn
      },
      {
        Sid    = "DenyAllOtherAccess"
        Effect = "Deny"
        NotPrincipal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.vpc_flow_logs[0].arn,
          "${aws_s3_bucket.vpc_flow_logs[0].arn}/*"
        ]
      }
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# VPC Flow Logs
resource "aws_flow_log" "this" {
  count                    = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn             = var.enable_cloudwatch_logging ? aws_iam_role.vpc_flow_logs[0].arn : null
  log_destination          = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : (var.enable_s3_logging ? aws_s3_bucket.vpc_flow_logs[0].arn : null)
  log_destination_type     = var.enable_cloudwatch_logging ? "cloud-watch-logs" : (var.enable_s3_logging ? "s3" : null)
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = 60

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs"
  })

  depends_on = local.flow_log_dependencies
}
