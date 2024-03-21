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
  region = "ap-southeast-2"
}

# VPC Count
module "main-vpc" {
  source     = "./modules/vpc"
  naming     = "pet"
  cidr_block = "10.0.0.0/16"
  tier       = 1
}

# Instance
module "instance" {
  source       = "./modules/ec2"
  naming       = "pet"
  myIp         = "61.85.118.29/32"
  defVpcId     = module.main-vpc.def-vpc-id
  pubSubIds    = module.main-vpc.public-sub-ids
  pvtSubIds    = module.main-vpc.private-sub-ids
  bastionAmi   = "ami-0868c56d68308169b"
  ansSrvAmi    = "ami-0868c56d68308169b"
  ansSrvType   = "t2.medium"
  ansSrvVolume = 30
  ansNodAmi    = "ami-0d6857b844e855670"
  ansNodType   = "t2.micro"
  ansNodVolume = 10
  ansNodCount  = 1
  keyName      = "pet-ec2"
}

output "bastion-pub-ip" {
  value = module.instance.bastion-public-ip
}

output "ans-srv-pvt-ip" {
  value = module.instance.ans-srv-pvt-ip
}

output "ansible-nod-ips" {
  value = module.instance.ansible-nod-ips
}
