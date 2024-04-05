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
    protocol    = "-1"
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
    Name = "${var.naming}_alb_sg"
  }
}
resource "aws_security_group" "kube_cluster_sg" {
  name   = "${var.naming}_ans_srv_sg"
  vpc_id = var.defVpcId

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }

  ingress {
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }
 
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }

  ingress {
    from_port       = 10252
    to_port         = 10252
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }

  ingress {
    from_port       = 10255
    to_port         = 10255
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }  
  
  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    cidr_blocks = [var.cidrBlock]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.kube_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.naming}_kube_cluster_sg"
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

# aws_key_pair resource 설정
resource "aws_key_pair" "terraform_key_pair" {
  # 등록할 key pair의 name
  key_name = var.keyName

  # public_key = "{.pub 파일 내용}"
  public_key = file("./.ssh/${var.keyName}.pub")

  tags = {
    description = "terraform key pair import"
  }
}

# Instance
resource "aws_instance" "bastion_host" {
  count           = length(var.pubSubIds)
  ami             = var.bastionAmi
  instance_type   = "t3.micro"
  subnet_id       = var.pubSubIds[count.index]
  key_name        = var.keyName
  security_groups = [aws_security_group.bastion_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "${var.naming}_bastion_host${count.index + 1}"
  }
}


resource "aws_instance" "kube_controller" {
  count         = 2
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = var.pvtSubAIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.jenkins-tg.arn} --targets Id=${self.id}"
  # }


  user_data = <<EOF
              #!/bin/bash
              EOF

  tags = {
    Name = "kube-controller${count.index + 1}"
    role = "kubecluster"
    feat = "controller"
  }
}

resource "aws_instance" "kube_controller_c" {
  count         = 1
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = var.pvtSubCIds[0]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.jenkins-tg.arn} --targets Id=${self.id}"

  # }

  # user_data = <<EOF
  #             #!/bin/bash
  #             sudo hostnamectl set-hostname kube-contoller${count.index + 3}
  #             sudo echo "127.0.1.1 kube-contoller${count.index + 3}" | sudo tee -a /etc/hosts
  #             EOF

  tags = {
    Name = "kube-controller${count.index + 1}"
    role = "kubecluster"
    feat = "controller"
  }
}

resource "aws_instance" "haproxy1" {
  count         = 1
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = var.pvtSubAIds[1]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.jenkins-tg.arn} --targets Id=${self.id}"
  # }


  # user_data = <<EOF
  #             #!/bin/bash
  #             sudo hostnamectl set-hostname haproxy${count.index +1}
  #             sudo echo "127.0.1.1 haproxy${count.index +1}" | sudo tee -a /etc/hosts              
  #             EOF

  tags = {
    Name = "haproxy${count.index + 1}"
    role = "kubecluster"
    feat = "haproxy"
  }
}

resource "aws_instance" "haproxy2" {
  count         = 1
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = var.pvtSubCIds[1]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }
    tags = {
    Name = "haproxy${count.index + 2}"
    role = "kubecluster"
    feat = "haproxy"
  }
}


resource "aws_instance" "kube_worker" {
  count         = var.kubeNodCount
  ami           = var.kubeNodAmi
  instance_type = var.kubeNodType
  subnet_id     = var.pvtSubAIds[2]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeNodVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.service-tg.arn} --targets Id=${self.id}"
  # }


  # user_data = <<EOF
  #             #!/bin/bash
  #             sudo hostnamectl set-hostname kube-worker${count.index + 1}
  #             sudo echo "127.0.1.1 kube-worker${count.index + 1}" | sudo tee -a /etc/hosts
  #             EOF

  tags = {
    Name = "kube-worker${count.index + 1}"
    role = "kubecluster"
    feat = "worker"
  }
}
resource "aws_instance" "kube_worker_c" {
  count         = var.kubeNodCount
  ami           = var.kubeNodAmi
  instance_type = var.kubeNodType
  subnet_id     = var.pvtSubCIds[2]
  key_name      = var.keyName

  vpc_security_group_ids = [aws_security_group.kube_cluster_sg.id]

  root_block_device {
    volume_size = var.kubeNodVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.service-tg.arn} --targets Id=${self.id}"
  # }


  # user_data = <<EOF
  #             #!/bin/bash
  #             sudo hostnamectl set-hostname kube-worker${count.index + 3}
  #             sudo echo "127.0.1.1 kube-worker${count.index + 3}" | sudo tee -a /etc/hosts
  #             EOF

  tags = {
    Name = "kube-worker${count.index + 3}"
    role = "kubecluster"
    feat = "worker"
  }
}