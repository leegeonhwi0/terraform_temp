variable "naming" {
  type    = string
  default = "def"
}

variable "cidrBlock" {
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

variable "pubSubIds" {
  type = list(string)
}

variable "pvtAppSubAIds" {
  type = string
}

variable "pvtAppSubCIds" {
  type = string
}

variable "pvtDBSubAIds" {
  type = string
}

variable "pvtDBSubCIds" {
  type = string
}

variable "kubeCtlType" {
  type = string
}

variable "kubeCtlVolume" {
  type = number
}

variable "kubeNodType" {
  type = string
}

variable "kubeNodVolume" {
  type = number
}

variable "kubeNodCount" {
  type = number
}

variable "keyName" {
  type = string
}

variable "bastionAmi" {
  type = string
}

variable "kubeCtlAmi" {
  type = string
}

variable "kubeNodAmi" {
  type = string
}
