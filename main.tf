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
  region = "ap-south-1"
}

# VPC Count
module "main_vpc" {
  source     = "./modules/vpc"
  naming     = "terraform_temp"
  cidrBlock = "10.0.0.0/16"
  tier       = 2
}

# Instance
module "instance" {
  source     = "./modules/ec2"
  naming     = "terraform-temp"
  myIp       = "61.85.118.29/32"
  defVpcId     = module.main_vpc.def_vpc_id
  cidrBlock    = "10.0.0.0/16"
  pubSubIds    = module.main_vpc.public_sub_ids
  pvtSubAIds   = module.main_vpc.private_sub_a_ids
  pvtSubCIds   = module.main_vpc.private_sub_c_ids
  bastionAmi = "ami-0bc47a3406a8143ba"
  kubeCtlAmi = "ami-0bc47a3406a8143ba"
  kubeCtlType = "t3.medium"
  kubeCtlVolume = 20
  kubeNodAmi = "ami-0bc47a3406a8143ba"
  kubeNodType = "t3.medium"
  kubeNodVolume = 10
  kubeNodCount = 2
  keyName = "terraform_temp-ec2"
}

# Output
output "bastion_pub_ip" {
  value = module.instance.bastion_public_ips
}

output "kube_controller_ip" {
  value = module.instance.kube_controller_ips
}

output "kube_controller_ip_c" {
  value = module.instance.kube_controller_ips_c
}

output "kube_worker_ips" {
  value = module.instance.kube_worker_ips
}

