# Configures the S3 backend for the Terraform state
# Note: You will need to create this S3 bucket manually before running `terraform init`.
# The bucket name must be globally unique.
terraform {
  # Specifies the S3 backend
  backend "s3" {
    # The name of the S3 bucket to store the state in
    bucket         = "mindapax-terraform-state-bucket"
    # The path to the state file in the S3 bucket
    key            = "terraform.tfstate"
    # The AWS region where the S3 bucket is located
    region         = "us-east-1"
    # Whether to encrypt the state file
    encrypt        = true
  }
}
