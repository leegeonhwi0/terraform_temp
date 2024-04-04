variable "naming" {
  type    = string
  default = "def"
}

variable "cidrBlock" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tier" {
  type    = number
  default = 1
}
