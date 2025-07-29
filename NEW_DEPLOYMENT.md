# New Deployment Process

This document explains the new, simplified deployment process for the Mindapax application.

## Architecture

The new architecture consists of:

*   **Frontend:** An Angular application hosted on a public S3 bucket.
*   **Backend:** A Spring Boot application running on an EC2 instance.
*   **Database:** An RDS MySQL database.

## Deployment

To deploy the application, you need to have the following tools installed:

*   [AWS CLI](https://aws.amazon.com/cli/)
*   [Terraform](https://www.terraform.io/downloads.html)
*   [Java 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html)
*   [Maven](https://maven.apache.org/download.cgi)
*   [Node.js and npm](https://nodejs.org/en/download/)

To deploy the application, simply run the following command from the root of the repository:

```bash
./deploy.sh
```

This script will:

1.  Build the frontend application.
2.  Build the backend application.
3.  Upload the frontend artifacts to the S3 bucket.
4.  Upload the backend JAR to the S3 bucket.
5.  Run `terraform apply` to create or update the infrastructure.

Terraform will create the following resources:

*   An S3 bucket for the frontend.
*   An EC2 instance for the backend.
*   A security group for the EC2 instance.
*   An IAM role and instance profile for the EC2 instance.
*   An RDS database.
*   A VPC, subnets, and other networking resources.

The EC2 instance is configured with a startup script that will:

1.  Install Java 17.
2.  Download the backend JAR from the S3 bucket.
3.  Run the backend application.

## Accessing the Application

Once the deployment is complete, you can access the application at the following URLs:

*   **Frontend:** The S3 bucket website endpoint. You can find this in the AWS console.
*   **Backend:** The public IP address of the EC2 instance, on port 8080. You can find this in the AWS console.

You will need to configure the frontend to use the backend's public IP address. You can do this by editing the `mindapax-frontend/src/environments/environment.ts` file.
