# Advanced Monitoring & Observability Platform

A production-grade observability platform built on AWS with a full monitoring stack: distributed tracing, metrics collection, log aggregation, alerting, and visualization — all provisioned with Terraform and deployed via Docker Compose.

---

## Architecture Overview

![Architecture Diagram](/assets/architecture.png)

### Flow Summary

* Client requests hit the Flask application
* OpenTelemetry instruments requests and sends traces to Jaeger
* Prometheus scrapes application and infrastructure metrics
* Grafana visualizes metrics and links traces
* Logs are shipped to CloudWatch with trace correlation

---

## Observability Pillars

| Pillar         | Tool                               | Purpose                                         |
| -------------- | ---------------------------------- | ----------------------------------------------- |
| Metrics        | Prometheus + Grafana               | Application (RED) + host infrastructure metrics |
| Traces         | Jaeger + OpenTelemetry             | Distributed request tracing                     |
| Logs           | JSON logging + CloudWatch          | Structured app logs with trace context          |
| Alerts         | Prometheus Alerting + AlertManager | Threshold-based alerting with routing           |
| Infrastructure | CloudWatch                         | EC2 CPU, network, status checks                 |

---

## Quick Start — Local (Docker Compose)

```bash
git clone https://github.com/IshKevin/advancedMonitoring.git
cd advancedMonitoring
docker compose up -d --build
```

![Docker Services Running](/assets/docker-running.png)

Access the services:

| Service      | URL                                              |
| ------------ | ------------------------------------------------ |
| Flask App    | [http://localhost:5000](http://localhost:5000)   |
| Grafana      | [http://localhost:3000](http://localhost:3000)   |
| Prometheus   | [http://localhost:9090](http://localhost:9090)   |
| Jaeger UI    | [http://localhost:16686](http://localhost:16686) |
| AlertManager | [http://localhost:9093](http://localhost:9093)   |

---

## Flask Application

![Flask API](/assets/flask-app.png)

### Endpoints

* `/` → service info
* `/health` → health check
* `/metrics` → Prometheus metrics
* `/api/users` → simulated workload
* `/api/simulate-error` → error generation
* `/api/simulate-latency` → latency testing

---

## Distributed Tracing (Jaeger + OpenTelemetry)

![Jaeger UI](/assets/jaeger.png)

### Features

* End-to-end request tracing
* Latency breakdown per service
* Trace correlation with logs and metrics

---

## Metrics Collection (Prometheus)

![Prometheus UI](/assets/prometheus.png)

### Responsibilities

* Scrapes Flask metrics
* Scrapes Node Exporter metrics
* Stores time-series data
* Evaluates alerts

---

## Visualization (Grafana)

### Observability Dashboard

![Grafana Observability](/assets/grafana-observability.png)

### Server Metrics Dashboard

![Grafana Server Metrics](/assets/grafana-server.png)

---

## Infrastructure Monitoring (Node Exporter)

![Node Exporter](/assets/node-exporter.png)

Tracks:

* CPU
* Memory
* Disk
* Network

---

## AWS Deployment (Terraform)

![AWS Infrastructure](/assets/aws-infra.png)

### Provisioned Resources

* EC2 instance (Docker host)
* S3 bucket (logs)
* CloudWatch (logs + metrics)
* IAM roles and policies


## Alerting

![AlertManager UI](/assets/alertmanager.png)

### Alerts

* High Error Rate
* High Latency
* Application Down

---

## Logs (CloudWatch)

![CloudWatch Logs](/assets/cloudwatch.png)

### Features

* Centralized logging
* Trace correlation
* Retention policies

---

## Project Structure

```
advancedMonitoring/
├── app/
├── prometheus/
├── alertmanager/
├── grafana/
├── infra/
├── scripts/
└── docker-compose.yml
```

---

## Development Workflow

```bash
# Update app
vim app/app.py

# Rebuild
docker compose up -d --build

# Generate traffic
ls

# Deploy
./scripts/build_push.sh
```

## Author

Kevin Ishimwe
