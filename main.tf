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
  region = "eu-west-2"
}

# VPC Count
module "main-vpc" {
  count      = 1
  source     = "./modules/vpc"
  naming     = "pet"
  cidr_block = "10.0.0.0/16"
}

# Bastion Host
module "bastion-host" {
  source   = "./modules/ec2"
  myIp     = "61.85.118.29/32"
  defVpcId = module.main-vpc[0].def-vpc-id
}
