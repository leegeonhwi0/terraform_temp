# Security Group
resource "aws_security_group" "bastion_sg" {
  name   = "${var.naming}_bastion_sg"
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
    protocol    = "_1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}_bastion_sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.naming}_alb_sg"
  vpc_id = var.defVpcId

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "_1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "_1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}_alb_sg"
  }
}

resource "aws_security_group" "ans_srv_sg" {
  name   = "${var.naming}_ans_srv_sg"
  vpc_id = var.defVpcId

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.myIp]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "_1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}_ans_srv_sg"
  }
}

resource "aws_security_group" "ans_nod_sg" {
  name   = "${var.naming}_ans_nod_sg"
  vpc_id = var.defVpcId

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ans_srv_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "_1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}_ans_nod_sg"
  }
}

# TargetGroup
resource "aws_lb_target_group" "service_tg" {
  name     = "${var.naming}-service-tg"
  port     = 8888
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

resource "aws_lb_target_group" "jenkins_tg" {
  name     = "${var.naming}-jenkins-tg"
  port     = 8080
  protocol = "HTTP"

  vpc_id = var.defVpcId

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

# LoadBalancer
resource "aws_lb" "srv_alb" {
  name               = "${var.naming}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.pubSubIds
}

# LB Listener
resource "aws_lb_listener" "srv_alb_http" {
  load_balancer_arn = aws_lb.srv_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_tg.arn
  }
}

resource "aws_lb_listener" "jenkins_alb_http" {
  load_balancer_arn = aws_lb.srv_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

# # aws_key_pair resource 설정
# resource "aws_key_pair" "terraform_key_pair" {
#   # 등록할 key pair의 name
#   key_name = var.keyName

#   # public_key = "{.pub 파일 내용}"
#   public_key = file("./.ssh/${var.keyName}.pub")

#   tags = {
#     description = "terraform key pair import"
#   }
# }

# Instance
resource "aws_instance" "bastion_host" {
  ami             = var.bastionAmi
  instance_type   = "t3.micro"
  subnet_id       = var.pubSubIds[0]
  key_name        = var.keyName
  security_groups = [aws_security_group.bastion_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "${var.naming}_bastion_host"
  }
}


resource "aws_instance" "ansible_server" {
  ami           = var.ansSrvAmi
  instance_type = var.ansSrvType
  subnet_id     = var.pvtSubAIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.ans_srv_sg.id]

  root_block_device {
    volume_size = var.ansSrvVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register_targets __target_group_arn ${aws_lb_target_group.jenkins_tg.arn} __targets Id=${self.id}"
  # }

  user_data = <<EOF
              #!/bin/bash
              sudo amazon_linux_extras enable ansible2
              sudo yum clean metadata
              sudo yum install -y ansible
              EOF

  tags = {
    Name = "ansible_server"
  }
}


resource "aws_instance" "ansible_nod" {
  count         = var.ansNodCount
  ami           = var.ansNodAmi
  instance_type = var.ansNodType
  subnet_id     = var.pvtSubAIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.ans_nod_sg.id]

  root_block_device {
    volume_size = var.ansNodVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register_targets __target_group_arn ${aws_lb_target_group.service_tg.arn} __targets Id=${self.id}"
  # }

  user_data = <<EOF
              #!/bin/bash
              sudo hostnamectl set_hostname ansible_agent0${count.index + 1}
              EOF

  tags = {
    Name = "ansible_nod_0${count.index + 1}"
  }
}
