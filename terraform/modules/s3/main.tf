resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-${var.environment}-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = { Name = "${var.project_name}-${var.environment}-logs" }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter { prefix = "alb-logs/" }

    expiration { days = 90 }

    noncurrent_version_expiration { noncurrent_days = 30 }
  }

  rule {
    id     = "expire-backups"
    status = "Enabled"

    filter { prefix = "backups/" }

    expiration { days = 30 }
  }
}

# Allow ALB to write access logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogs"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::718504428378:root"  # ELB service account — ap-south-1
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.main.arn}/alb-logs/*"
      },
      {
        Sid    = "AllowAWSLogDelivery"
        Effect = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.main.arn}/alb-logs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowAWSLogDeliveryAcl"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.main.arn
      }
    ]
  })
}
