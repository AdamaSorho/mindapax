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

Before running the deployment scripts, you need to make them executable. You can do this by running the following commands from the root of the repository:

**Important:** Before running the deployment script for the first time, you must manually terminate the Elastic Beanstalk environment in the AWS console. This is necessary to avoid conflicts with the new EC2-based deployment.

```bash
chmod +x deploy.sh
chmod +x deploy-backend.sh
chmod +x deploy-frontend.sh
```

### Full Deployment

To deploy both the backend and the frontend, run the following command from the root of the repository:

```bash
./deploy.sh
```

This script will:

1.  Deploy the backend by running the `deploy-backend.sh` script.
2.  Get the backend's public IP address from the Terraform output.
3.  Deploy the frontend by running the `deploy-frontend.sh` script with the backend's URL.

### Separate Deployment

You can also deploy the backend and frontend separately.

#### Backend Deployment

To deploy the backend, run the following command from the root of the repository:

```bash
./deploy-backend.sh
```

This script will:

1.  Build the backend application.
2.  Upload the backend JAR to the S3 bucket.
3.  Run `terraform apply` to create or update the infrastructure.

After the deployment is complete, Terraform will output the public IP address of the backend EC2 instance. You will need this for the frontend deployment.

#### Frontend Deployment

To deploy the frontend, run the following command from the root of the repository, replacing `<backend_url>` with the public IP address of the backend EC2 instance:

```bash
./deploy-frontend.sh http://<backend_url>:8080
```

This script will:

1.  Update the frontend's environment file with the backend URL.
2.  Build the frontend application.
3.  Upload the frontend artifacts to the S3 bucket.

## Accessing the Application

Once the deployment is complete, you can access the application at the following URLs:

*   **Frontend:** The S3 bucket website endpoint. You can get this from the output of the `terraform apply` command, or from the AWS console.
*   **Backend:** The public IP address of the EC2 instance, on port 8080.
