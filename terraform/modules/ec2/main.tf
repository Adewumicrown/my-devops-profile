resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    aws_region       = var.aws_region
    ecr_registry_url = var.ecr_registry_url
    image_name       = var.image_name
    log_group_name   = var.log_group_name
  }))

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  }
}
