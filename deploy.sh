#!/bin/bash

# Exit on error
set -e

# Build the frontend
echo "Building the frontend..."
cd mindapax-frontend
npm install
npm run build
cd ..

# Build the backend
echo "Building the backend..."
cd mindapax-backend
mvn clean package -DskipTests
cd ..

# Upload the frontend to S3
echo "Uploading the frontend to S3..."
aws s3 sync mindapax-frontend/dist/mindapax-frontend s3://mindapax-frontend-bucket --delete

# Upload the backend to S3
echo "Uploading the backend to S3..."
aws s3 cp mindapax-backend/target/*.jar s3://mindapax-backend-bucket/mindapax-backend.jar

# Deploy the infrastructure using Terraform
echo "Deploying the infrastructure using Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Deployment complete!"
