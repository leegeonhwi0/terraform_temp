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
  security_groups    = [var.albSGIds]
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

resource "aws_lb_listener" "jenkins_alb_nodeport" {
  load_balancer_arn = aws_lb.srv_alb.arn
  port              = 30080
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
  security_groups = [var.bastionSGIds]

  associate_public_ip_address = true

  user_data = file("${path.module}/user_data/user_data_bastion_host.sh")

  tags = {
    Name = "${var.naming}_bastion_host${count.index + 1}"
  }
}

resource "aws_instance" "VPN_host" {
  ami             = var.bastionAmi
  instance_type   = "t3.micro"
  subnet_id       = var.pubSubIds[0]
  key_name        = var.keyName
  security_groups = [var.bastionSGIds]
  user_data       = file("${path.module}/user_data/user_data_VPN_host.sh")
  tags = {
    Name = "${var.naming}_VPN_host"
  }
}

resource "aws_eip" "VPN-eip" {
  domain = "vpc"
  lifecycle {
    create_before_destroy = true
  }
  instance = aws_instance.VPN_host.id
}

resource "aws_instance" "kube_controller" {
  count         = var.kubeCtlCount
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = count.index % 2 == 0 ? var.pvtAppSubAIds : var.pvtAppSubCIds
  key_name      = var.keyName

  vpc_security_group_ids = [var.kubeControllerSGIds]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.jenkins-tg.arn} --targets Id=${self.id}"
  # }


  user_data = file("${path.module}/user_data/user_data_kubecontroller.sh")

  tags = {
    Name = "${var.naming}-kube-controller${count.index + 1}"
    role = "${var.naming}-kubecluster"
    feat = "${var.naming}-controller"
  }
}


resource "aws_instance" "haproxy" {
  count         = length(var.pubSubIds)
  ami           = var.kubeCtlAmi
  instance_type = var.kubeCtlType
  subnet_id     = count.index % 2 == 0 ? var.pvtAppSubAIds : var.pvtAppSubCIds
  key_name      = var.keyName

  vpc_security_group_ids = [var.kubeControllerSGIds]

  root_block_device {
    volume_size = var.kubeCtlVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.jenkins-tg.arn} --targets Id=${self.id}"
  # }
  user_data = file("${path.module}/user_data/user_data_haproxy.sh")

  tags = {
    Name = "${var.naming}-haproxy${count.index + 1}"
    role = "${var.naming}-kubecluster"
    feat = "${var.naming}-haproxy"
  }
}



resource "aws_instance" "kube_worker" {
  count         = var.kubeNodCount
  ami           = var.kubeNodAmi
  instance_type = var.kubeNodType
  subnet_id     = count.index % 2 == 0 ? var.pvtAppSubAIds : var.pvtAppSubCIds
  key_name      = var.keyName

  vpc_security_group_ids = [var.kubeWorkerSGIds]

  root_block_device {
    volume_size = var.kubeNodVolume
  }

  # provisioner "local_exec" {
  #   command = "aws elbv2 register-targets --target-group-arn ${aws-lb-target-group.${var.naming}-service-tg.arn} --targets Id=${self.id}"
  # }

  tags = {
    Name = "${var.naming}-kube-worker${count.index + 1}"
    role = "${var.naming}-kubecluster"
    feat = "${var.naming}-worker"
  }
}

resource "aws_instance" "db" {
  count           = length(var.pubSubIds)
  ami             = var.kubeNodAmi
  instance_type   = var.kubeNodType
  key_name        = var.keyName
  subnet_id       = count.index % 2 == 0 ? var.pvtDBSubCIds : var.pvtDBSubCIds
  security_groups = [var.dbMysqlSGIds]

  root_block_device {
    volume_size = var.kubeNodVolume
  }

  user_data = file("${path.module}/user_data/user_data_db_mysql.sh")


  tags = {
    Name = "${var.naming}-db-${count.index % 2 == 0 ? "Primary" : "Secondary"}"
  }
}
