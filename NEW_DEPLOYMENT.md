# New Deployment Process

This document explains the new, simplified deployment process for the Mindapax application.

## Architecture

The new architecture consists of:

*   **Frontend:** An Angular application hosted on a public S3 bucket.
*   **Backend:** A Spring Boot application running on an EC2 instance.
*   **Database:** An RDS MySQL database.
*   **Cloudflare Worker (optional but recommended):** Proxies the public custom domain to the S3 bucket over HTTPS and provides SPA fallback.

## Deployment

To deploy the application, you need to have the following tools installed:

*   [AWS CLI](https://aws.amazon.com/cli/)
*   [Terraform](https://www.terraform.io/downloads.html)
*   [Java 21](https://adoptium.net/temurin/releases/)
*   [Maven](https://maven.apache.org/download.cgi)
*   [Node.js and npm](https://nodejs.org/en/download/)

Before running the deployment scripts, you need to make them executable. You can do this by running the following commands from the root of the repository:

**Important:** Before running the deployment script for the first time, you must manually terminate the Elastic Beanstalk environment in the AWS console. This is necessary to avoid conflicts with the new EC2-based deployment.

```bash
chmod +x deploy.sh
chmod +x deploy-backend.sh
chmod +x deploy-frontend.sh
```

If you plan to serve the frontend over a custom domain via Cloudflare, also make the helper scripts executable:

```bash
chmod +x cloudflare/deploy-proxy.sh
chmod +x cloudflare/cleanup-proxy.sh
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
4.  (Optional) Deploy/refresh the Cloudflare Worker proxy to serve the frontend over HTTPS on your custom domain.

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
4.  (Optional) Deploy/refresh the Cloudflare Worker proxy to map your custom domain to the S3 bucket.

### Cloudflare Proxy (Frontend HTTPS + Custom Domain)

If you use a custom domain like `mindapx.lafabriqueduleader.com`, deploy the Worker proxy so the SPA is served over HTTPS and keeps the custom host:

1. Set `S3_HOST` to your bucket host (e.g., `your-bucket.s3.us-east-1.amazonaws.com`). Avoid the `s3-website-` endpoint; use the HTTPS virtual-hosted style.
2. Deploy the worker script from `cloudflare/cloudflare-proxy-worker.js` (or `dev-config-sets/cloudflare-proxy-worker.js`) using Cloudflare dashboard or `wrangler`.
3. Add a route in Cloudflare: `mindapx.lafabriqueduleader.com/*` -> this Worker.
4. Ensure DNS for `mindapx.lafabriqueduleader.com` proxies through Cloudflare and has a valid cert (orange cloud on).

Note: The Worker includes SPA fallback to `/index.html` for S3 403/404 responses.

## Accessing the Application

Once the deployment is complete, you can access the application at the following URLs:

*   **Frontend:** The S3 bucket website endpoint. You can get this from the output of the `terraform apply` command, or from the AWS console.
*   **Backend:** The public IP address of the EC2 instance, on port 8080.
*   **Custom Domain (optional):** `https://<your custom domain>` served via Cloudflare Worker proxy to S3 (e.g., `https://mindapx.lafabriqueduleader.com`).
