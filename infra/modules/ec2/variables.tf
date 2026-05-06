variable "app_name" {
  description = "Application name used as resource name prefix"
  type        = string
  default     = "advanced-monitoring"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "github_repo" {
  description = "GitHub repository URL to clone on EC2"
  type        = string
  default     = "https://github.com/IshKevin/advancedMonitoring.git"
}

variable "vpc_id" {
  description = "VPC ID to place the security group in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
