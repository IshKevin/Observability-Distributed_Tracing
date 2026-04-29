#!/bin/bash
# Build the Flask app Docker image and push it to ECR.
# Run this after `terraform apply` so the ECR repo exists.
# Usage: ./scripts/build_push.sh [IMAGE_TAG]

set -euo pipefail

IMAGE_TAG="${1:-latest}"

# Resolve ECR URL from Terraform output (requires terraform init + apply first)
ECR_URL=$(terraform -chdir=terraform output -raw ecr_repository_url 2>/dev/null)
AWS_REGION=$(terraform -chdir=terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

if [ -z "$ECR_URL" ]; then
  echo "ERROR: Could not read ecr_repository_url from terraform output."
  echo "       Run 'terraform -chdir=terraform apply' first."
  exit 1
fi

echo "==> ECR repository : $ECR_URL"
echo "==> Image tag       : $IMAGE_TAG"
echo ""

# Authenticate Docker to ECR
echo "==> Authenticating with ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_URL"

# Build
echo "==> Building image..."
docker build \
  --platform linux/amd64 \
  -t "${ECR_URL}:${IMAGE_TAG}" \
  ./app

# Push
echo "==> Pushing image..."
docker push "${ECR_URL}:${IMAGE_TAG}"

echo ""
echo "==> Done! Image pushed: ${ECR_URL}:${IMAGE_TAG}"
echo "    Force a new ECS deployment with:"
echo "    aws ecs update-service --cluster \$(terraform -chdir=terraform output -raw ecs_cluster_name) \\"
echo "      --service advanced-monitoring-service --force-new-deployment"
