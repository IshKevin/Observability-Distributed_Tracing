#!/bin/bash
set -euo pipefail

exec > /var/log/app-init.log 2>&1

# Install Docker and Git
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# Clone the repository
git clone ${github_repo} /opt/app

# Build the Flask app image
cd /opt/app
docker build -t flask-app:latest ./app

# Run the Flask app container
docker run -d \
  --name flask-app \
  --restart unless-stopped \
  -p 5000:5000 \
  -e OTEL_SERVICE_NAME=flask-app \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://${monitoring_private_ip}:4317 \
  -e ENVIRONMENT=${environment} \
  flask-app:latest

echo "Flask app started" >> /var/log/app-init.log
