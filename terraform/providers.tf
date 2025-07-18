# Specifies the providers required by the configuration
terraform {
  # Specifies the required providers
  required_providers {
    # Specifies the AWS provider
    aws = {
      # The source of the provider
      source  = "hashicorp/aws"
      # The version of the provider
      version = "~> 4.0"
    }
  }
}

# Configures the AWS provider
provider "aws" {
  # The AWS region to use
  region = "us-east-1"
}
