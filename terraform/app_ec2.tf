resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(templatefile("${path.module}/userdata/app.sh.tpl", {
    github_repo           = var.github_repo
    monitoring_private_ip = aws_instance.monitoring.private_ip
    environment           = var.environment
  }))

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.app_name}-app"
    Role    = "app"
    Project = var.app_name
  }

  depends_on = [aws_instance.monitoring]
}
