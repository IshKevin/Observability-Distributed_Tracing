#!/bin/bash
set -euo pipefail

exec > /var/log/monitoring-init.log 2>&1

# Install Docker and Docker Compose plugin
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Create directory structure
mkdir -p /opt/monitoring/{prometheus,alertmanager,grafana/{provisioning/{datasources,dashboards},dashboards}}

# ---------------------------------------------------------------------------
# Prometheus — uses EC2 service discovery so no hardcoded app IP is needed.
# The monitoring EC2 instance profile has ec2:DescribeInstances permission.
# ---------------------------------------------------------------------------
cat > /opt/monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    environment: "${environment}"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: flask-app
    ec2_sd_configs:
      - region: ${aws_region}
        port: 5000
        filters:
          - name: "tag:Project"
            values: ["${app_name}"]
          - name: "tag:Role"
            values: ["app"]
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "$1:5000"
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        target_label: private_ip
EOF

# Alert rules (rendered from prometheus/alert_rules.yml at terraform apply time)
cat > /opt/monitoring/prometheus/alert_rules.yml << 'RULES'
${alert_rules}
RULES

# ---------------------------------------------------------------------------
# Alertmanager
# ---------------------------------------------------------------------------
cat > /opt/monitoring/alertmanager/alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ["alertname"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: log-receiver

receivers:
  - name: log-receiver
    webhook_configs:
      - url: "http://localhost:5001/alerts"
        send_resolved: true
EOF

# ---------------------------------------------------------------------------
# Grafana provisioning — datasources use localhost because all containers
# share the host network (network_mode: host).
# ---------------------------------------------------------------------------
cat > /opt/monitoring/grafana/provisioning/datasources/datasources.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true

  - name: Jaeger
    type: jaeger
    uid: jaeger
    access: proxy
    url: http://localhost:16686
    editable: true
    jsonData:
      nodeGraph:
        enabled: true
EOF

cat > /opt/monitoring/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1
providers:
  - name: default
    orgId: 1
    folder: Observability
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# ---------------------------------------------------------------------------
# Docker Compose — host network so Prometheus can reach instance metadata
# for EC2 service discovery and all services talk via localhost.
# ---------------------------------------------------------------------------
cat > /opt/monitoring/docker-compose.yml << 'EOF'
version: "3.8"

services:
  jaeger:
    image: jaegertracing/all-in-one:1.58
    network_mode: host
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:v2.52.0
    network_mode: host
    volumes:
      - /opt/monitoring/prometheus:/etc/prometheus:ro
      - prometheus-data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --web.enable-lifecycle
    restart: unless-stopped

  alertmanager:
    image: prom/alertmanager:v0.27.0
    network_mode: host
    volumes:
      - /opt/monitoring/alertmanager:/etc/alertmanager:ro
    command:
      - --config.file=/etc/alertmanager/alertmanager.yml
    restart: unless-stopped

  grafana:
    image: grafana/grafana:11.0.0
    network_mode: host
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - /opt/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
      - /opt/monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafana-data:/var/lib/grafana
    restart: unless-stopped

volumes:
  prometheus-data:
  grafana-data:
EOF

# Copy Grafana dashboard JSON from the repo if it was cloned, otherwise skip
if [ -f /opt/app/grafana/dashboards/observability.json ]; then
  cp /opt/app/grafana/dashboards/observability.json \
     /opt/monitoring/grafana/dashboards/observability.json
fi

cd /opt/monitoring
docker compose up -d

echo "Monitoring stack started" >> /var/log/monitoring-init.log
