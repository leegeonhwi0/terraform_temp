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
  naming     = "pet"
  cidr_block = "172.0.0.0/16"
  tier       = 3
}

# Instance
module "instance" {
  source       = "./modules/ec2"
  myIp         = "61.85.118.29/32"
  defVpcId     = module.main-vpc.def-vpc-id
  pubSubIds    = module.main-vpc.public-sub-ids
  pvtSubIds    = module.main-vpc.private-sub-ids
  ansSrvType   = "t2.medium"
  ansSrvVolume = 20
  ansNodType   = "t2.micro"
  ansNodVolume = 8
  ansCount     = 1
  keyName      = "pet-ec2"
}


output "service-alb-ip" {
  value = module.instance.srv-alb-eip-ip
}
