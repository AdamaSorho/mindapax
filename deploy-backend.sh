#!/bin/bash

# Exit on error
set -e

# Build the backend
echo "Building the backend..."
cd mindapax-backend
mvn clean package -DskipTests
cd ..

# Upload the backend to S3
echo "Uploading the backend to S3..."
aws s3 cp mindapax-backend/target/*.jar s3://mindapax-backend-bucket/mindapax-backend.jar

# Deploy the infrastructure using Terraform
echo "Deploying the infrastructure using Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Backend deployment complete!"
