# The URL for the frontend application
output "frontend_url" {
  # The value of the output
  value = aws_cloudfront_distribution.frontend.domain_name
}

# The URL for the backend application
output "backend_url" {
  # The value of the output
  value = aws_elastic_beanstalk_environment.backend.cname
}
