locals {
  az-1 = "us-east-1a"
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
  cidr_block        = cidrsubnet(var.cidr_block, 8, 10)
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pub-sub-a"
  }
}

output "public-sub-id" {
  value = aws_subnet.pub-sub-a.id
}

# Create Private Subnet
resource "aws_subnet" "pvt-sub-a" {
  count             = var.tier
  vpc_id            = aws_vpc.def-vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 20 + count.index)
  availability_zone = local.az-1
  tags = {
    Name = "${var.naming}-pvt-sub-a-${count.index + 1}"
  }
}

output "private-sub-ids" {
  value = { for idx, subnet in aws_subnet.pvt-sub-a : idx => subnet.id }
}

# Create Internet Gatway
resource "aws_internet_gateway" "def-igw" {
  vpc_id = aws_vpc.def-vpc.id
  tags = {
    Name = "${var.naming}-igw"
  }
}

# Create a Public Route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.def-vpc.id
  tags = {
    Name = "${var.naming}-public-route-table"
  }
}

# Create a Private Route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.def-vpc.id
  tags = {
    Name = "${var.naming}-private-route-table"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public-route-table-association" {
  subnet_id      = aws_subnet.pub-sub-a.id
  route_table_id = aws_route_table.public-route-table.id
}

# Private Route Table Association
resource "aws_route_table_association" "private-route-table-association" {
  count          = 2
  subnet_id      = aws_subnet.pvt-sub-a[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

# Create a EIP
resource "aws_eip" "eip" {
  domain = "vpc"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.naming}-nat"
  }
}

# Create NAT Gatway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub-sub-a.id
  tags = {
    Name = "${var.naming}-pvt-ngw-a"
  }
}

# Associate Public Subnet with Internet Gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.def-igw.id
}

# Associate Private Subnets with NAT Gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway.id
}
