provider "aws" {
  region = "us-west-2"
}

# S3 Bucket
resource "aws_s3_bucket" "nextjs_bucket" {
  bucket = "nextjs-portfolio-yy-12345"
}

# Ownership Control (disable ACLs)
resource "aws_s3_bucket_ownership_controls" "nextjs_bucket_ownership_controls" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "nextjs_bucket_public_access_block" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for Next.JS portfolio site"
}

# Allow CloudFront to read from S3
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"

        Principal = {
          AWS = aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
        }

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.nextjs_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "nextjs_distribution" {

  depends_on = [
    aws_s3_bucket_policy.nextjs_bucket_policy
  ]

  enabled = true

  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.nextjs_bucket.bucket_regional_domain_name
    origin_id   = "S3-nextjs-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {

    target_origin_id = "S3-nextjs-origin"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {

    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
