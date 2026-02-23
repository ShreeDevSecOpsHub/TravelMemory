# Web Server EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(file("${path.module}/web_server_init.sh"))

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-web-root"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "durga-web-server"
  }

  depends_on = [aws_internet_gateway.main]
}

# Elastic IP for Web Server
resource "aws_eip" "web_server_eip" {
  domain            = "vpc"
  instance          = aws_instance.web_server.id
  network_interface = aws_instance.web_server.primary_network_interface_id

  tags = {
    Name = "durga-web-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Database Server EC2 Instance
resource "aws_instance" "db_server" {
  ami                    = var.ami_id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_pair_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(file("${path.module}/db_server_init.sh"))

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-db-root"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "durga-db-server"
  }
}
