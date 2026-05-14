variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization percentage that triggers the high-CPU alarm"
  type        = number
  default     = 80
}

