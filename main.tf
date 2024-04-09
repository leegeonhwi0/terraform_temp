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
  source    = "./modules/vpc"
  naming    = "gymfit-test"
  cidrBlock = "10.0.0.0/16"
  tier      = 3
}

# Instance
module "instance" {
  source        = "./modules/ec2"
  naming        = "gymfit-test"
  myIp          = "222.118.135.114/32"
  defVpcId      = module.main_vpc.def_vpc_id
  cidrBlock     = "10.0.0.0/16"
  pubSubIds     = module.main_vpc.public_sub_ids
  pvtAppSubAIds = module.main_vpc.pri_app_sub_a_ids
  pvtAppSubCIds = module.main_vpc.pri_app_sub_c_ids
  pvtDBSubAIds  = module.main_vpc.pri_db_sub_a_ids
  pvtDBSubCIds  = module.main_vpc.pri_db_sub_c_ids
  bastionAmi    = "ami-0bc47a3406a8143ba"
  kubeCtlAmi    = "ami-0bc47a3406a8143ba"
  kubeCtlType   = "t3.medium"
  kubeCtlVolume = 20
  kubeNodAmi    = "ami-0bc47a3406a8143ba"
  kubeNodType   = "t3.medium"
  kubeNodVolume = 20
  kubeNodCount  = 2
  keyName       = "gymfit_test-ec2"
}

# Output
output "bastion-pub-ip" {
  value = module.instance.bastion_public_ips
}

output "kube-controller-ip" {
  value = module.instance.kube_controller_ips
}


output "kube-worker-ip" {
  value = module.instance.kube_worker_ips
}


output "haproxy-ip" {
  value = module.instance.haproxy_ips
}


