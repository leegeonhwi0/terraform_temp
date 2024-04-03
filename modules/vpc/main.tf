locals {
  az_1 = "ap_south_1a"
  az_2 = "ap_south_1c"
}

# Create VPC
resource "aws_vpc" "def_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.naming}_vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "pub_a" {
  vpc_id            = aws_vpc.def_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone = local.az_1
  tags = {
    Name = "${var.naming}_pub_a"
  }
}

resource "aws_subnet" "pub_c" {
  vpc_id            = aws_vpc.def_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 2)
  availability_zone = local.az_2
  tags = {
    Name = "${var.naming}_pub_c"
  }
}

# Create Private Subnet
resource "aws_subnet" "pvt_a" {
  count             = var.tier
  vpc_id            = aws_vpc.def_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 10 + count.index)
  availability_zone = local.az_1
  tags = {
    Name = "${var.naming}_pvt_a_0${count.index + 1}"
  }
}

resource "aws_subnet" "pvt_c" {
  count             = var.tier
  vpc_id            = aws_vpc.def_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 20 + count.index)
  availability_zone = local.az_2
  tags = {
    Name = "${var.naming}_pvt_c_0${count.index + 1}"
  }
}


# Create Internet Gatway
resource "aws_internet_gateway" "def_igw" {
  vpc_id = aws_vpc.def_vpc.id
  tags = {
    Name = "${var.naming}_igw"
  }
}

# Create a Public Route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.def_vpc.id
  tags = {
    Name = "${var.naming}_public_route_table"
  }
}

# Create a Private Route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.def_vpc.id
  tags = {
    Name = "${var.naming}_private_route_table"
  }
}

# Public Route Table Association A
resource "aws_route_table_association" "public_route_table_association_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Public Route Table Association C
resource "aws_route_table_association" "public_route_table_association_c" {
  subnet_id      = aws_subnet.pub_c.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table Association A
resource "aws_route_table_association" "private_route_table_association_a" {
  count          = var.tier
  subnet_id      = aws_subnet.pvt_a[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Private Route Table Association C
resource "aws_route_table_association" "private_route_table_association_c" {
  count          = var.tier
  subnet_id      = aws_subnet.pvt_c[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Create a EIP
resource "aws_eip" "nat_a_eip" {
  domain = "vpc"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.naming}_nat_a"
  }
}

resource "aws_eip" "nat_c_eip" {
  domain = "vpc"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.naming}_nat_c"
  }
}

# Create NAT Gatway
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a_eip.id
  subnet_id     = aws_subnet.pub_a.id
  tags = {
    Name = "${var.naming}_pub_a_ngw"
  }
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c_eip.id
  subnet_id     = aws_subnet.pub_c.id
  tags = {
    Name = "${var.naming}_pub_c_ngw"
  }
}

# Associate Public Subnet with Internet Gateway
resource "aws_route" "pub_r" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.def_igw.id
}

# Associate Private Subnets with NAT Gateway
resource "aws_route" "private_r_a" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a.id
}

resource "aws_route" "private_r_c" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_c.id
}
