# The password for the database
variable "db_password" {
  # A description of the variable
  description = "The password for the database"
  # The type of the variable
  type        = string
  # Whether the variable is sensitive
  sensitive   = true
}

variable "zoom_secret_key" {
  # A description of the variable
  description = "The Zoom secret key"
  # The type of the variable
  type        = string
  # Whether the variable is sensitive
  sensitive   = true
}

variable "zoom_sdk_key" {
  # A description of the variable
  description = "The Zoom SDK key"
  # The type of the variable
  type        = string
  # Whether the variable is sensitive
  sensitive   = true
}

variable "zoom_api_account_id" {
  description = "The Zoom API account ID"
  type        = string
  sensitive   = true
}

variable "zoom_api_client_id" {
  description = "The Zoom API client ID"
  type        = string
  sensitive   = true
  
}

variable "zoom_api_client_secret" {
  description = "The Zoom API client secret"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "The JWT secret"
  type        = string
  sensitive   = true
}

variable "jwt_expiration_time" {
  description = "The JWT expiration time"
  type        = number
  default = 3600000
}

variable "jwt_refresh_token_expiration_ms" {
  description = "The JWT refresh token expiration time"
  type        = number
  default = 86400000
}

variable "spring_profiles_active" {
  description = "The Spring profiles active"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_s3_bucket_name" {
  description = "The AWS S3 bucket name"
  type        = string
  default     = "mindapax-bucket"
}
