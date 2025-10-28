output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend assets."
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_website_endpoint" {
  description = "S3 static website endpoint."
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "s3_bucket_regional_domain_name" {
  description = "Regional S3 domain name (useful when fronting with Cloudflare as a custom origin)."
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}
