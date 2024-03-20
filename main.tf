# Terraform Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.1"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "us-east-1"
}

# VPC Count
module "main-vpc" {
  source     = "./modules/vpc"
  naming     = "petclinic"
  cidr_block = "10.0.0.0/16"
  tier       = 2
}

# Instance
module "instance" {
  source       = "./modules/ec2"
  naming       = "petclinic"
  myIp         = "61.85.118.29/32"
  defVpcId     = module.main-vpc.def-vpc-id
  pubSubIds    = module.main-vpc.public-sub-ids
  pvtSubIds    = module.main-vpc.private-sub-ids
  ansSrvType   = "t2.medium"
  ansSrvVolume = 30
  ansNodType   = "t2.micro"
  ansNodVolume = 8
  ansNodCount  = 2
  keyName      = "petclinic-ec2"
}

output "bastion-pub-ip" {
  value = module.instance.bastion-public-ip
}

output "ans-srv-pvt-ip" {
  value = module.instance.ans-srv-pvt-ip
}

output "ansible-nod-ids" {
  value = module.instance.ansible-nod-ids
}

resource "null_resource" "save-nod-pvt-ip" {
  depends_on = [module.instance]

  # 인벤토리 이름 추가
  provisioner "local-exec" {
    command = "echo [agent] > ansi-pvt-ips.txt"
  }

  # ansible-nod-ids 값을 받아서 파일에 추가
  provisioner "local-exec" {
    command = "aws ec2 describe-instances --instance-ids ${module.instance.ansible-nod-ids} --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text >> ansi-pvt-ips.txt"
  }
}
