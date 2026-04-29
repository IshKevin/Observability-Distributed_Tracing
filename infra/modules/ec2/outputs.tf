output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.this.public_ip
}

output "key_name" {
  description = "Name of the generated key pair"
  value       = aws_key_pair.this.key_name
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}
