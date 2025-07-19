# Terraform Configuration for Mindapax

This directory contains the Terraform configuration for deploying the Mindapax application on AWS.

## AWS CodeBuild

This project uses AWS CodeBuild to automatically build and deploy the frontend and backend applications. There are two CodeBuild projects:

*   `mindapax-frontend`: Builds and deploys the frontend application to an S3 bucket.
*   `mindapax-backend`: Builds and deploys the backend application to an Elastic Beanstalk environment.

To trigger a build, you can either push a change to the GitHub repository or start a build manually in the AWS CodeBuild console.

### Secrets

This project uses a `terraform.tfvars` file to manage secrets. This file is not committed to the repository and must be created locally. The following variables must be defined in the `terraform.tfvars` file:

*   `db_password`: The password for the database.
*   `zoom_secret_key`: The Zoom secret key.

Here is an example of what the `terraform.tfvars` file should look like:

```
db_password = "your-db-password"
zoom_secret_key = "your-zoom-secret-key"
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS credentials configured

## Usage

1. **Create the S3 backend bucket:**

   You will need to create an S3 bucket to store the Terraform state. The bucket name must be globally unique. You can create the bucket using the AWS CLI:

   ```bash
   aws s3 mb s3://<your-unique-bucket-name>
   ```

2. **Update the backend configuration:**

   Open the `backend.tf` file and replace `mindapax-terraform-state-bucket` with the name of the S3 bucket you created in the previous step.

3. **Initialize Terraform:**

   ```bash
   terraform init
   ```

4. **Plan the deployment:**

   ```bash
   terraform plan -var "db_password=<your-database-password>"
   ```

5. **Apply the changes:**

   ```bash
   terraform apply -var "db_password=<your-database-password>"
   ```

## Inputs

| Name          | Description               | Type   | Default | Required |
|---------------|---------------------------|--------|---------|----------|
| `db_password` | The password for the database | string | n/a     | yes      |

## Outputs

| Name           | Description                        |
|----------------|------------------------------------|
| `frontend_url` | The URL for the frontend application |
| `backend_url`  | The URL for the backend application  |
