data "aws_availability_zones" "available" {
  state = "available"
}

# VPC resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# public network setup

resource "aws_internet_gateway" "igateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names
  cidr_block        = local.pub_cidrs
}


# Public Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public_subnets" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igateway.id

  timeouts {
    create = "5m"
  }
}

#private network setup
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names
  cidr_block        = local.priv_cidrs
}

#resource "aws_eip" "nat" {
#  count = var.num_subnets_private
#  vpc   = true
#}
#
#resource "aws_nat_gateway" "private" {
#  count         = var.num_subnets_private
#  subnet_id     = aws_subnet.private.*.id[count.index]
#  allocation_id = aws_eip.nat.*.id[count.index]
#}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igateway.id

  timeouts {
    create = "5m"
  }
}
