output "backend_ip" {
  value = aws_instance.backend.public_ip
}

output "frontend_url" {
  value = "http://${aws_s3_bucket.frontend.website_endpoint}"
}
