output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "EC2 public IP address"
  value       = module.ec2.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${module.ec2.key_name}.pem ubuntu@${module.ec2.public_ip}"
}

output "app_url" {
  description = "Flask application URL"
  value       = "http://${module.ec2.public_ip}:5000"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${module.ec2.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${module.ec2.public_ip}:9090"
}

output "jaeger_url" {
  description = "Jaeger distributed tracing UI URL"
  value       = "http://${module.ec2.public_ip}:16686"
}

output "alertmanager_url" {
  description = "Alertmanager UI URL"
  value       = "http://${module.ec2.public_ip}:9093"
}

output "s3_bucket_name" {
  description = "S3 bucket name for logs and artifacts"
  value       = module.s3.bucket_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.cloudwatch.log_group_name
}
