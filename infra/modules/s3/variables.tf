variable "app_name" {
  description = "Application name used as bucket name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "force_destroy" {
  description = "Allow destroying the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Days before log objects are deleted"
  type        = number
  default     = 90
}
