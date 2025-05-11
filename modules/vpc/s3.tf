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
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    id     = "expire_old_logs"
    status = "Enabled"

    filter {
      prefix = "flow-logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}



# S3 Bucket for Access Logs
resource "aws_s3_bucket" "log_receiver" {
  count         = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket        = "${local.names.vpc}-flow-logs-access-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-flow-logs-access-bucket"
  })
}

# S3 Bucket Versioning for Access Logs
resource "aws_s3_bucket_versioning" "log_receiver" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.log_receiver[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block for Access Logs Bucket
resource "aws_s3_bucket_public_access_block" "log_receiver" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.log_receiver[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Server-Side Encryption for Access Logs Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "log_receiver" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.log_receiver[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 Bucket Lifecycle Configuration for Access Logs
resource "aws_s3_bucket_lifecycle_configuration" "log_receiver" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.log_receiver[0].id

  rule {
    id     = "expire_old_logs"
    status = "Enabled"

    filter {
      prefix = "access-logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

# S3 Bucket Event Notifications for Access Logs
resource "aws_s3_bucket_notification" "log_receiver" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.log_receiver[0].id

  topic {
    topic_arn     = aws_sns_topic.log_receiver[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "access-logs/"
  }
}

# SNS Topic for Access Logs Notifications
resource "aws_sns_topic" "log_receiver" {
  count = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  name  = "${local.names.vpc}-access-logs-notifications"

  tags = merge(local.common_tags, {
    Name = "${local.names.vpc}-access-logs-notifications"
  })
}

# S3 Bucket Logging Configuration
resource "aws_s3_bucket_logging" "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs && var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  target_bucket = aws_s3_bucket.log_receiver[0].id
  target_prefix = "flow-logs/"
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
      }
    ]
  })
}
