#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl git

curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu


git clone "${github_repo}" "/opt/${app_name}"
cd "/opt/${app_name}"
docker compose up -d --build
