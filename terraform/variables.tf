variable "project_name" {
  description = "Friendly name used for tagging resources."
  type        = string
  default     = "mindapax-frontend"
}

variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket that will host the static frontend."
  type        = string
  default     = "mindapax.com"
}

variable "index_document" {
  description = "Default index document for the static website."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Default error document for the static website."
  type        = string
  default     = "404.html"
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects."
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to read objects (default allows everyone; replace with Cloudflare IP ranges for tighter control)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Map of additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
