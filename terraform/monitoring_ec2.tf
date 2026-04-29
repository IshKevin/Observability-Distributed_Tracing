resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.monitoring_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(templatefile("${path.module}/userdata/monitoring.sh.tpl", {
    aws_region  = var.aws_region
    app_name    = var.app_name
    alert_rules = file("${path.module}/../prometheus/alert_rules.yml")
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.app_name}-monitoring"
    Role    = "monitoring"
    Project = var.app_name
  }
}
