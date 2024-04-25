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
  region = "sa-east-1"
}

# VPC Count
module "main_vpc" {
  source    = "./modules/vpc"
  naming    = "gymfit-test"
  cidrBlock = "10.0.0.0/16"
}
# sg module set
module "sg" {
  source                        = "./modules/sg"
  naming                        = "gymfit-test"
  cidrBlock                     = "10.0.0.0/16"
  kube_controller_ingress_rules = var.kube_controller_ingress_rules
  kube_worker_ingress_rules     = var.kube_worker_ingress_rules
  defVpcId                      = module.main_vpc.def_vpc_id
  myIp                          = "118.42.18.181/32"
}

# Instance
module "instance" {
  source              = "./modules/ec2"
  naming              = "gymfit-test"
  myIp                = "118.42.18.181/32"
  defVpcId            = module.main_vpc.def_vpc_id
  cidrBlock           = "10.0.0.0/16"
  pubSubIds           = module.main_vpc.public_sub_ids
  pvtAppSubAIds       = module.main_vpc.pri_app_sub_a_ids
  pvtAppSubCIds       = module.main_vpc.pri_app_sub_c_ids
  pvtDBSubAIds        = module.main_vpc.pri_db_sub_a_ids
  pvtDBSubCIds        = module.main_vpc.pri_db_sub_c_ids
  kubeControllerSGIds = module.sg.kube_controller_sg_id
  kubeWorkerSGIds     = module.sg.kube_worker_sg_id
  albSGIds            = module.sg.alb_sg_id
  bastionSGIds        = module.sg.bastion_sg_id
  dbMysqlSGIds        = module.sg.db_mysql_sg_id
  bastionAmi          = "ami-084dc6d47813a2785"
  kubeCtlAmi          = "ami-084dc6d47813a2785"
  kubeCtlType         = "t3.medium"
  kubeCtlVolume       = 20
  kubeCtlCount        = 3
  kubeNodAmi          = "ami-084dc6d47813a2785"
  kubeNodType         = "t3.medium"
  kubeNodVolume       = 20
  kubeNodCount        = 3
  keyName             = "gymfit_test-ec2"
}

