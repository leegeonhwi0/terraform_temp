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

resource "aws_instance" "bastion-ec2" {
  ami             = "ami-02d7fd1c2af6eead0"
  instance_type   = "t2.micro"
  subnet_id       = var.pubSubId
  key_name        = "my-ec2-01"
  security_groups = [aws_security_group.bastion-sg.id]

  associate_public_ip_address = true
  tags = {
    Name = "${var.naming}-bastion-ec2"
  }
}

output "bastion-public-ip" {
  value = aws_instance.bastion-ec2.public_ip
}
