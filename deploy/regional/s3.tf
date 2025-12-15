# S3 bucket for audit logs with WORM compliance
resource "aws_s3_bucket" "audit" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

# Enable versioning (required for object lock)
resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable object lock with compliance mode (WORM)
resource "aws_s3_bucket_object_lock_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }

  # Object lock must be enabled at bucket creation
  # This will fail if the bucket already exists without object lock
  depends_on = [aws_s3_bucket_versioning.audit]
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "audit" {
  bucket = aws_s3_bucket.audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy to manage old versions
resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    # Delete expired object delete markers
    expiration {
      expired_object_delete_marker = true
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
