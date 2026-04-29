output "app_public_ip" {
  description = "Public IP of the Flask app EC2"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Flask app endpoint"
  value       = "http://${aws_instance.app.public_ip}:5000"
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring EC2"
  value       = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  description = "Grafana UI"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus UI"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "jaeger_url" {
  description = "Jaeger UI"
  value       = "http://${aws_instance.monitoring.public_ip}:16686"
}

output "alertmanager_url" {
  description = "Alertmanager UI"
  value       = "http://${aws_instance.monitoring.public_ip}:9093"
}

output "ssh_app" {
  description = "SSH command for the app EC2"
  value       = var.key_pair_name != "" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.app.public_ip}" : "No key pair configured"
}

output "ssh_monitoring" {
  description = "SSH command for the monitoring EC2"
  value       = var.key_pair_name != "" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.monitoring.public_ip}" : "No key pair configured"
}
