output "cpu_alarm_name" {
  description = "CloudWatch CPU alarm name"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "status_alarm_name" {
  description = "CloudWatch status check alarm name"
  value       = aws_cloudwatch_metric_alarm.status_check.alarm_name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
