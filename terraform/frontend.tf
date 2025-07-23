# Creates a new S3 bucket for the frontend application
resource "aws_s3_bucket" "frontend" {
  # The name of the S3 bucket
  bucket = "mindapax-frontend-bucket"
}

# Configure S3 bucket for website hosting
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"  # For SPA routing
  }
}

# Block all public access to the S3 bucket (CloudFront will access via OAC)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Creates a new S3 bucket for logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "mindapax-frontend-log-bucket"
}

# Creates a new S3 bucket for backend artifacts
resource "aws_s3_bucket" "backend" {
  bucket = "mindapax-backend-bucket"
}

# Block public access for backend bucket
resource "aws_s3_bucket_public_access_block" "backend" {
  bucket = aws_s3_bucket.backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"

  depends_on = [aws_s3_bucket.frontend]
}

# Create Origin Access Control (OAC) instead of OAI
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "mindapax-frontend-oac"
  description                       = "OAC for Mindapax frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Creates a new S3 bucket policy for the frontend bucket (updated for OAC)
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.frontend]
}

# Creates a new CloudFront distribution for the frontend application
resource "aws_cloudfront_distribution" "frontend" {
  # The origin for the CloudFront distribution
  origin {
    # The domain name of the origin
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    # The ID of the origin
    origin_id                = "S3-mindapax-frontend"
    # Use OAC instead of OAI
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Whether the distribution is enabled
  enabled             = true
  # Whether the distribution is IPv6 enabled
  is_ipv6_enabled     = true
  # A comment for the distribution
  comment             = "Mindapax frontend distribution"
  # The default root object for the distribution
  default_root_object = "index.html"

  # Custom error pages for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # The default cache behavior for the distribution
  default_cache_behavior {
    # The allowed HTTP methods
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    # The cached HTTP methods
    cached_methods         = ["GET", "HEAD"]
    # The ID of the origin to associate the cache behavior with
    target_origin_id       = "S3-mindapax-frontend"
    # Use managed cache policy
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    # Use managed origin request policy
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin

    # The viewer protocol policy to use
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # The price class for the distribution
  price_class = "PriceClass_100"

  # The restrictions for the distribution
  restrictions {
    # The geo restriction for the distribution
    geo_restriction {
      # The type of geo restriction
      restriction_type = "none"
    }
  }

  # The viewer certificate for the distribution
  viewer_certificate {
    # Whether to use the CloudFront default certificate
    cloudfront_default_certificate = true
  }

  # Add tags
  tags = {
    Name = "mindapax-frontend-distribution"
  }
}

# Output the CloudFront distribution domain name
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.frontend.arn
}