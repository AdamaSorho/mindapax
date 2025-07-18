output "frontend_url" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "backend_url" {
  value = aws_elastic_beanstalk_environment.backend.cname
}
