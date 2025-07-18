# Note: You will need to create this S3 bucket manually before running `terraform init`.
# The bucket name must be globally unique.
terraform {
  backend "s3" {
    bucket         = "mindapax-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
