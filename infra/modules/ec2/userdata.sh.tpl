#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl git

# Install Docker via the official convenience script
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Clone repo and start all services
git clone ${github_repo} /opt/${app_name}
cd /opt/${app_name}
docker compose up -d --build

# Install CloudWatch agent
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-Config 2>/dev/null || true
