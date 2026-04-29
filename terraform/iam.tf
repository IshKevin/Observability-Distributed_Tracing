# IAM role for the monitoring EC2 so Prometheus can call ec2:DescribeInstances
# for EC2 service discovery without hardcoded IPs.

resource "aws_iam_role" "monitoring" {
  name = "${var.app_name}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "monitoring_ec2_describe" {
  name = "${var.app_name}-ec2-describe"
  role = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.app_name}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}
