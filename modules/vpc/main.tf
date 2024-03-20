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
  cidr_block        = cidrsubnet("${var.cidr_block}", 8, 10)
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pub-sub-a"
  }
}

output "public-sub-a-id" {
  value = aws_subnet.pub-sub-a.id
}

# Create Private Subnet
resource "aws_subnet" "pvt-sub-a" {
  count             = var.tier
  vpc_id            = aws_vpc.def-vpc.id
  cidr_block        = cidrsubnet("${var.cidr_block}", 8, 20 + count.index)
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pvt-sub-a-${count.index}"
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
