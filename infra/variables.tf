variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Project name used as prefix for all resource names"
  type        = string
  default     = "advanced-monitoring"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.app_name))
    error_message = "app_name must be lowercase alphanumeric characters and hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for running the Docker monitoring stack"
  type        = string
  default     = "t3.small"
}

variable "github_repo" {
  description = "GitHub repository URL cloned on EC2 to run docker compose"
  type        = string
  default     = "https://github.com/IshKevin/advancedMonitoring.git"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the instance (SSH and service ports)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "Every entry in allowed_cidr_blocks must be a valid IPv4 CIDR."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}
