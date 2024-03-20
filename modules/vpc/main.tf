locals {
  az-1 = "us-east-1a"
  az-2 = "us-east-1c"
}

# Create VPC
resource "aws_vpc" "def-vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.naming}-vpc"
  }
}

output "def-vpc-id" {
  value = aws_vpc.def-vpc.id
}

# Create Public Subnet
resource "aws_subnet" "pub-sub-a" {
  vpc_id            = aws_vpc.def-vpc.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pub-sub-a"
  }
}

# Create Private Subnet
resource "aws_subnet" "pvt-sub-a" {
  vpc_id            = aws_vpc.def-vpc.id
  cidr_block        = "10.10.13.0/24"
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pvt-sub-a"
  }
}

# Create Internet Gatway
resource "aws_internet_gateway" "def-igw" {
  vpc_id = aws_vpc.def-vpc.id
  tags = {
    Name = "${var.naming}-igw"
  }
}

# # Create NAT Gatway
# resource "aws_nat_gateway" "pvt-ngw-a" {
#   connectivity_type = "private"
#   subnet_id         = aws_subnet.pub-sub-a[0].id
#   tags = {
#     Name = "${var.naming}-pvt-ngw-a"
#   }
# }
