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

# Bastion Host
module "bastion-host" {
  source   = "./modules/ec2"
  myIp     = "61.85.118.29/32"
  defVpcId = module.main-vpc.def-vpc-id
  pubSubId = module.main-vpc.public-sub-a-id
}
