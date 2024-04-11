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
  naming     = "gf-stag"
  cidrBlock = "10.0.0.0/16"
}
# sg module set
module "sg" {
  source    = "./modules/sg"
  naming    = "gf-stag"
  cidrBlock = "10.0.0.0/16"
  defVpcId      = module.main_vpc.def_vpc_id
  myIp = "61.85.118.29/32"
  kube_controller_ingress_rules = var.kube_controller_ingress_rules
  kube_worker_ingress_rules = var.kube_worker_ingress_rules
#  bastion_ingress_rules = var.bastion_ingress_rules
}

# Instance
module "instance" {
  source        = "./modules/ec2"
  naming        = "gf-stag"
  myIp          = "61.85.118.29/32"
  defVpcId      = module.main_vpc.def_vpc_id
  cidrBlock     = "10.0.0.0/16"
  pubSubIds     = module.main_vpc.public_sub_ids
  pvtAppSubAIds = module.main_vpc.pri_app_sub_a_ids
  pvtAppSubCIds = module.main_vpc.pri_app_sub_c_ids
  pvtDBSubAIds  = module.main_vpc.pri_db_sub_a_ids
  pvtDBSubCIds  = module.main_vpc.pri_db_sub_c_ids
  kubeControllerSGIds = module.sg.kube_controller_sg_id
  kubeWorkerSGIds = module.sg.kube_worker_sg_id
  albSGIds      = module.sg.alb_sg_id
  bastionSGIds  = module.sg.bastion_sg_id
  bastionAmi    = "ami-0bc47a3406a8143ba"
  kubeCtlAmi    = "ami-0bc47a3406a8143ba"
  kubeCtlType   = "t3.medium"
  kubeCtlVolume = 20
  kubeCtlCount  = 3
  kubeNodAmi    = "ami-0bc47a3406a8143ba"
  kubeNodType   = "t3.medium"
  kubeNodVolume = 10
  kubeNodCount  = 2
  keyName       = "gf-stag-ec2"
}



