#!/bin/bash


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

echo "==> Building image..."
docker build --platform linux/amd64 -t "$IMAGE_REF" ./app

REMOTE_CMD="docker load \
  && docker stop flask-app 2>/dev/null || true \
  && docker rm flask-app 2>/dev/null || true \
  && docker run -d --name flask-app --restart unless-stopped \
     -p 5000:5000 -e OTEL_SERVICE_NAME=flask-app -e ENVIRONMENT=production \
     ${IMAGE_REF}"


echo "==> Transferring image to EC2..."
docker save "$IMAGE_REF" \
  | ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$REMOTE_CMD"

echo ""
echo "==> Deployed flask-app:${IMAGE_TAG} to http://${APP_IP}:5000"
