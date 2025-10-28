# Mindapax Frontend Terraform

This Terraform configuration provisions an AWS S3 bucket configured for static website hosting. Pair it with Cloudflare (or another CDN) by pointing your DNS to the S3 website endpoint or by using the regional domain as a custom origin.

## Prerequisites

- Terraform `>= 1.5`
- AWS credentials with permissions to manage S3, CloudFront, and IAM
- (Optional) Cloudflare zone + certificate if you plan to front the bucket with Cloudflare

## Quick start

```bash
cd terraform
terraform init
terraform plan \
  -var="aws_region=us-east-1" \
  -var="bucket_name=mindapax.com" \
  -var='allowed_cidr_blocks=["103.21.244.0/22","103.22.200.0/22", "0.0.0.0/0"]'  # replace with Cloudflare IP ranges

terraform apply
```

### Key variables

- `bucket_name` (default `mindapax.com`): must be globally unique.
- `allowed_cidr_blocks`: list of source IPs allowed to read from the bucket. Set it to the Cloudflare IP ranges for stricter access control (defaults to `0.0.0.0/0`).

All variables are defined with defaults in `variables.tf`.

## Outputs

- `s3_bucket_name` – bucket hosting the frontend.
- `s3_bucket_website_endpoint` – direct S3 website endpoint (useful for smoke tests).
- `s3_bucket_regional_domain_name` – regional S3 domain (use this as Cloudflare origin if you prefer private REST access over the website endpoint).

## Deploying the frontend

1. Run `terraform apply` as shown above.
2. Upload the Angular build artifacts (e.g. `dist/`) to the S3 bucket:
   ```bash
   aws s3 sync mindapax-frontend/dist s3://mindapax.com --delete
   ```
3. In Cloudflare (or your DNS provider), create a CNAME pointing to the S3 website endpoint (`s3_bucket_website_endpoint`) or set the regional domain name as the origin for a Cloudflare proxy.

## Cleanup

```bash
terraform destroy
```

Set `force_destroy = true` if you want Terraform to remove the bucket even when it contains objects.
