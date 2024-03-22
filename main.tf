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
  naming     = "mini3prjt"
  cidr_block = "10.0.0.0/16"
  tier       = 1
}

# Instance
module "instance" {
  source     = "./modules/ec2"
  naming     = "mini3prjt"
  myIp       = "61.85.118.29/32"
  defVpcId   = module.main-vpc.def-vpc-id
  pubSubIds   = module.main-vpc.public-sub-ids
  pvtSubIds  = module.main-vpc.private-sub-ids
  bastionAmi = "ami-02d7fd1c2af6eead0"
  ansSrvAmi = "ami-02d7fd1c2af6eead0"
  ansSrvType = "t3.medium"
  ansSrvVolume = 30
  ansNodAmi = "ami-02d7fd1c2af6eead0"
  ansNodType = "t3.micro"
  ansNodVolume = 10
  ansNodCount = 3
  keyName = "mini3prjt-ec2"
}

# Output
output "bastion-pub-ip" {
  value = module.instance.bastion-public-ip
}

output "ans-srv-pvt-ip" {
  value = module.instance.ans-srv-pvt-ip
}

output "ansible-nod-ips" {
  value = module.instance.ansible-nod-ips
}

