variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Project name used as a resource prefix and tag"
  type        = string
  default     = "advanced-monitoring"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the single public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access (leave empty to skip)"
  type        = string
  default     = ""
}

variable "app_instance_type" {
  description = "EC2 instance type for the Flask app"
  type        = string
  default     = "t3.small"
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for the monitoring stack"
  type        = string
  default     = "t3.medium"
}

variable "github_repo" {
  description = "HTTPS URL of the GitHub repo to clone onto the app EC2"
  type        = string
  default     = "https://github.com/IshKevin/advancedMonitoring.git"
}

variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to reach monitoring UIs and SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
