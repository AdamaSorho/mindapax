#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Print commands and their arguments as they are executed.
set -x

# 1. Build the application using Maven.
echo "Building the application..."
mvn clean package -DskipTests

# 2. Package the application into a ZIP file.
echo "Packaging the application..."
JAR_FILE=$(find target -name "*.jar" | head -1)
if [ -z "$JAR_FILE" ]; then
  echo "No JAR file found!"
  exit 1
fi
echo "Found JAR file: $JAR_FILE"
cp "$JAR_FILE" mindapax-backend.jar
zip mindapax-backend.zip mindapax-backend.jar

# 3. Upload the ZIP file to S3.
echo "Uploading to S3..."
aws s3 cp mindapax-backend.zip s3://mindapax-backend-bucket/

# 4. Create a new application version in Elastic Beanstalk.
echo "Creating application version..."
VERSION_LABEL="v$(date +%Y%m%d%H%M%S)-local"
aws elasticbeanstalk create-application-version \
  --application-name mindapax-backend \
  --version-label "$VERSION_LABEL" \
  --source-bundle S3Bucket=mindapax-backend-bucket,S3Key=mindapax-backend.zip

# 5. Update the Elastic Beanstalk environment to deploy the new version.
echo "Updating environment..."
aws elasticbeanstalk update-environment \
  --application-name mindapax-backend \
  --environment-name mindapax-backend-env \
  --version-label "$VERSION_LABEL"

echo "Deployment complete!"
