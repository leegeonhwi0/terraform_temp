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
