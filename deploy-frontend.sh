#!/bin/bash

# Exit on error
set -e

if [ -z "$1" ]; then
  echo "Usage: ./deploy-frontend.sh <backend_url>"
  exit 1
fi

BACKEND_URL=$1

# Update the frontend environment file
echo "Updating the frontend environment file..."
sed -i "s|apiUrl: '.*'|apiUrl: '$BACKEND_URL'|" mindapax-frontend/src/environments/environment.ts

# Build the frontend
echo "Building the frontend..."
cd mindapax-frontend
npm install
npm run build
cd ..

# Upload the frontend to S3
echo "Uploading the frontend to S3..."
aws s3 sync mindapax-frontend/dist/mindapax-frontend s3://mindapax-frontend-bucket --delete

echo "Frontend deployment complete!"
