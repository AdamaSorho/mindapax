#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/mindapax-frontend"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

usage() {
  cat <<USAGE
Usage: $0 [-e env_name] [--skip-build] [--dry-run]

Options:
  -e, --env NAME     Optional environment profile (maps to Angular configuration name).
                     Defaults to "production".
  --skip-build       Skip Angular build step (use existing dist contents).
  --dry-run          Print actions without executing AWS uploads.
  -h, --help         Show this help message.
USAGE
}

ENV_NAME="production"
SKIP_BUILD=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENV_NAME="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

AWS_BUCKET_NAME=$(terraform -chdir="$TERRAFORM_DIR" output -raw s3_bucket_name 2>/dev/null || true)
S3_WEBSITE_ENDPOINT=$(terraform -chdir="$TERRAFORM_DIR" output -raw s3_bucket_website_endpoint 2>/dev/null || true)

if [[ -z "$AWS_BUCKET_NAME" ]]; then
  echo "ERROR: Unable to retrieve s3_bucket_name from Terraform outputs. Have you run 'terraform apply'?" >&2
  exit 1
fi

if [[ $SKIP_BUILD -eq 0 ]]; then
  echo "==> Installing frontend dependencies"
  (cd "$FRONTEND_DIR" && npm install)

  echo "==> Building Angular app (configuration: $ENV_NAME)"
  (cd "$FRONTEND_DIR" && npx ng build --configuration "$ENV_NAME")
else
  echo "==> Skipping Angular build as requested"
fi

BUILD_DIR="$FRONTEND_DIR/dist"
if [[ ! -d "$BUILD_DIR" ]]; then
  echo "ERROR: Build directory '$BUILD_DIR' not found." >&2
  exit 1
fi

# Angular 17+ application builder outputs dist/<project>/browser by default.
# Detect the first project folder, then prefer the nested "browser" directory if it exists.
DIST_SUBDIR="$(ls -1 "$BUILD_DIR" | head -n 1)"
DIST_PATH="$BUILD_DIR/$DIST_SUBDIR"
if [[ ! -d "$DIST_PATH" ]]; then
  echo "ERROR: Unable to locate compiled assets under '$DIST_PATH'." >&2
  exit 1
fi

if [[ -d "$DIST_PATH/browser" ]]; then
  DIST_PATH="$DIST_PATH/browser"
fi

echo "==> Syncing assets to s3://$AWS_BUCKET_NAME"
SYNC_COMMAND=(aws s3 sync "$DIST_PATH" "s3://$AWS_BUCKET_NAME" --delete)

if [[ $DRY_RUN -eq 1 ]]; then
  echo "DRY RUN: ${SYNC_COMMAND[*]}"
else
  "${SYNC_COMMAND[@]}"
fi

echo "Deployment complete."
if [[ -n "$S3_WEBSITE_ENDPOINT" ]]; then
  echo "S3 website endpoint: http://$S3_WEBSITE_ENDPOINT"
  echo "Note: DNS/Cloudflare configuration should point to this endpoint or use it as origin."
fi
