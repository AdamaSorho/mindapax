# Creates a new S3 bucket for the frontend application
resource "aws_s3_bucket" "frontend" {
  # The name of the S3 bucket
  bucket = "mindapax-frontend-bucket"
}

# Creates a new S3 bucket for logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "mindapax-frontend-log-bucket"
}

resource "aws_s3_bucket_logging" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Creates a new CloudFront origin access identity
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for Mindapax frontend"
}

# Creates a new S3 bucket policy for the frontend bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
      },
    ]
  })
}

# Creates a new CloudFront distribution for the frontend application
resource "aws_cloudfront_distribution" "frontend" {
  # The origin for the CloudFront distribution
  origin {
    # The domain name of the origin
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    # The ID of the origin
    origin_id   = "S3-mindapax-frontend"

    # The S3 origin configuration for the origin
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  # Whether the distribution is enabled
  enabled             = true
  # Whether the distribution is IPv6 enabled
  is_ipv6_enabled     = true
  # A comment for the distribution
  comment             = "Mindapax frontend distribution"
  # The default root object for the distribution
  default_root_object = "index.html"

  # The default cache behavior for the distribution
  default_cache_behavior {
    # The allowed HTTP methods
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    # The cached HTTP methods
    cached_methods   = ["GET", "HEAD"]
    # The ID of the origin to associate the cache behavior with
    target_origin_id = "S3-mindapax-frontend"

    # The forwarded values for the cache behavior
    forwarded_values {
      # Whether to forward query strings to the origin
      query_string = false
      # The cookies to forward to the origin
      cookies {
        # Whether to forward all cookies, no cookies, or a whitelist of cookies
        forward = "none"
      }
    }

    # The viewer protocol policy to use
    viewer_protocol_policy = "redirect-to-https"
    # The minimum TTL for the cache behavior
    min_ttl                = 0
    # The default TTL for the cache behavior
    default_ttl            = 3600
    # The maximum TTL for the cache behavior
    max_ttl                = 86400
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
}
