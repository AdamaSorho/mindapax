#!/bin/bash

# Exit on error
set -e

# Build the Spring Boot application
echo "Building the Spring Boot application..."
cd mindapax-backend
mvn clean package -DskipTests
cd ..

# Deploy the application using Terraform
echo "Deploying the application using Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Deployment complete!"
