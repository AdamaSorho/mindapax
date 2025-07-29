#!/bin/bash

# Exit on error
set -e

# Deploy the backend
echo "Deploying the backend..."
./deploy-backend.sh

# Get the backend URL from the Terraform output
echo "Getting the backend URL..."
BACKEND_URL=$(cd terraform && terraform output -raw backend_ip)

# Deploy the frontend
echo "Deploying the frontend..."
./deploy-frontend.sh http://$BACKEND_URL:8080

echo "Deployment complete!"
