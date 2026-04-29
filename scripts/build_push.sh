#!/bin/bash
# Build the Flask app image locally, then deploy it to the app EC2 via SSH.
# Usage: ./scripts/build_push.sh [IMAGE_TAG]
#
# Requirements: terraform must have been applied, key_pair_name must be set.

set -euo pipefail

IMAGE_TAG="${1:-latest}"

APP_IP=$(terraform -chdir=terraform output -raw app_public_ip 2>/dev/null)
KEY_PAIR=$(terraform -chdir=terraform output -raw ssh_app 2>/dev/null \
           | grep -oP '(?<=~/.ssh/)[^.]+(?=\.pem)' || echo "")

if [ -z "$APP_IP" ]; then
  echo "ERROR: Could not read app_public_ip from terraform output."
  echo "       Run 'terraform -chdir=terraform apply' first."
  exit 1
fi

echo "==> Target EC2  : $APP_IP"
echo "==> Image tag   : $IMAGE_TAG"
echo ""

SSH_OPTS=(-o StrictHostKeyChecking=no)
[ -n "$KEY_PAIR" ] && SSH_OPTS+=(-i "${HOME}/.ssh/${KEY_PAIR}.pem")

IMAGE_REF="flask-app:${IMAGE_TAG}"
SSH_TARGET="ec2-user@${APP_IP}"

# Build image locally for linux/amd64
echo "==> Building image..."
docker build --platform linux/amd64 -t "$IMAGE_REF" ./app

# Pre-build the remote command so SSH receives a single, fully-expanded string
# (avoids SC2029 — no bare variable expansions inside the ssh argument).
REMOTE_CMD="docker load \
  && docker stop flask-app 2>/dev/null || true \
  && docker rm flask-app 2>/dev/null || true \
  && docker run -d --name flask-app --restart unless-stopped \
     -p 5000:5000 -e OTEL_SERVICE_NAME=flask-app -e ENVIRONMENT=production \
     ${IMAGE_REF}"

# Save and transfer to EC2 — REMOTE_CMD is fully expanded locally before SSH
# receives it, so client-side expansion is intentional (SC2029).
echo "==> Transferring image to EC2..."
# shellcheck disable=SC2029
docker save "$IMAGE_REF" \
  | ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$REMOTE_CMD"

echo ""
echo "==> Deployed flask-app:${IMAGE_TAG} to http://${APP_IP}:5000"
