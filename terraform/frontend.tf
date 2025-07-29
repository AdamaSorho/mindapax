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

# Allow public read access to the S3 bucket
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
