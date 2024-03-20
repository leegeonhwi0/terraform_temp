variable "naming" {
  type    = string
  default = "def"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "myIp" {
  type    = string
  default = "0.0.0.0/0"
}

variable "defVpcId" {
  type = string
}

variable "pubSubId" {
  type = string
}
