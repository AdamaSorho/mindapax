output "backend_ip" {
  value = aws_instance.backend.public_ip
}

output "database_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "database_port" {
  value = aws_db_instance.default.port
}

# output "frontend_url" {
#   value = "http://${aws_s3_bucket.frontend.website_endpoint}"
# }
