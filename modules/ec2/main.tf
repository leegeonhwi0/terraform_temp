# Security Group
resource "aws_security_group" "bastion-sg" {
  name   = "${var.naming}-bastion-sg"
  vpc_id = var.defVpcId

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIp]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}-bastion-sg"
  }
}

resource "aws_security_group" "alb-sg" {
  name   = "${var.naming}-alb-sg"
  vpc_id = var.defVpcId

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}-alb-sg"
  }
}

resource "aws_security_group" "ans-srv-sg" {
  name   = "${var.naming}-ans-srv-sg"
  vpc_id = var.defVpcId

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}-ans-srv-sg"
  }
}

resource "aws_security_group" "ans-nod-sg" {
  name   = "${var.naming}-ans-nod-sg"
  vpc_id = var.defVpcId

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}-ans-nod-sg"
  }
}

# TargetGroup
resource "aws_lb_target_group" "service-tg" {
  name     = "${var.naming}-service-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.defVpcId

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Elastic IP
resource "aws_eip" "srv-alb-eip" {
  domain = "vpc"
}

# LoadBalancer
resource "aws_lb" "srv-alb" {
  name               = "${var.naming}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = var.pubSubIds
}

# Associate EIP with Load Balancer
resource "aws_eip_association" "srv-alb-eip-assoc" {
  allocation_id = aws_eip.srv-alb-eip.id
  instance_id   = aws_lb.srv-alb.id
}

output "srv-alb-eip-ip" {
  value = aws_eip.srv-alb-eip.public_ip
}

# LB Listener Rule
resource "aws_lb_listener_rule" "service-tg-rule" {
  listener_arn = aws_lb.srv-alb.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service-tg.arn
  }

  condition {
    path_pattern {
      values = ["/path"]
    }
  }
}

# Instance
resource "aws_instance" "bastion-host" {
  ami             = "ami-02d7fd1c2af6eead0"
  instance_type   = "t2.micro"
  subnet_id       = var.pubSubIds[0]
  key_name        = var.keyName
  security_groups = [aws_security_group.bastion-sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "${var.naming}-bastion-host"
  }
}

output "bastion-public-ip" {
  value = aws_instance.bastion-host.public_ip
}

resource "aws_instance" "ansible-server" {
  ami           = "ami-02d7fd1c2af6eead0"
  instance_type = var.ansSrvType
  subnet_id     = var.pvtSubIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.ans-srv-sg.id]

  root_block_device {
    volume_size = var.ansSrvVolume
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname ansible-server
              sudo amazon-linux-extras enable ansible2
              sudo yum clean all
              sudo yum update -y
              sudo pip3 install 'ansible-core>=2.13.9' 
              sudo pip3 install boto3 botocore
              sudo ansible-galaxy collection install amazon.aws
              EOF

  tags = {
    Name = "ansible-server"
  }
}

resource "aws_instance" "ansible-nod" {
  count         = var.ansCount
  ami           = "ami-02d7fd1c2af6eead0"
  instance_type = var.ansNodType
  subnet_id     = var.pvtSubIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.ans-nod-sg.id]

  root_block_device {
    volume_size = var.ansNodVolume
  }

  provisioner "local-exec" {
    command = "aws elbv2 register-targets --target-group-arn ${aws_lb_target_group.service-tg.arn} --targets Id=${self.id}"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname ansible-agent
              sudo amazon-linux-extras enable ansible2
              sudo yum clean all
              sudo yum update -y
              sudo pip3 install 'ansible-core>=2.13.9' 
              sudo pip3 install boto3 botocore
              EOF

  tags = {
    Name = "ansible-nod-${count.index}"
  }
}
