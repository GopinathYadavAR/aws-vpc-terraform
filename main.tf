terraform {
  required_providers {
    # terraform aws version
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  # terraform version
  required_version = ">= 0.14.9"
}

# create the VPC
resource "aws_vpc" "my-eks-vpc" {
  cidr_block       = var.main-vpc-cidr
  instance_tenancy = "default"
  tags             = { name = "my eks vpc" }
}
resource "aws_eip" "nateIP" {
  count = length(var.private-subnets-cidr)
  vpc   = true
  tags = {

    Name = "elastic-ip"
    Desc = "This elastic IP in public subnet ${element(aws_subnet.my-eks-public-subnets.*.id, count.index)}"
  }
}

# create the internet gateway and attach to vpc
resource "aws_internet_gateway" "my-eks-internet-gateway" {
  vpc_id = aws_vpc.my-eks-vpc.id
  tags   = { name = "my eks internet gateway" }
}

#create the public subnet
resource "aws_subnet" "my-eks-public-subnets" {
  count             = length(var.public-subnets-cidr)
  vpc_id            = aws_vpc.my-eks-vpc.id
  cidr_block        = element(var.public-subnets-cidr, count.index)
  availability_zone = element(var.azs, count.index)
  tags              = { name = "my eks public subnet-${count.index + 1}" }
}
# create the private subnet
resource "aws_subnet" "my-eks-private-subnets" {
  count             = length(var.private-subnets-cidr)
  vpc_id            = aws_vpc.my-eks-vpc.id
  cidr_block        = element(var.private-subnets-cidr, count.index)
  availability_zone = element(var.azs, count.index)
  tags              = { name = "my eks private subnet-${count.index + 1}" }
}
#create the nat gateway and attach to vpc
resource "aws_nat_gateway" "my-eks-nat-gateway" {
  count         = length(var.private-subnets-cidr)
  allocation_id = element(aws_eip.nateIP.*.id, count.index)
  subnet_id     = element(aws_subnet.my-eks-public-subnets.*.id, count.index)
  tags          = { name = "my eks nat gateway nat-gateway-${count.index + 1}" }
}
#create route table for public subnets
resource "aws_route_table" "my-eks-public-route-table" {
  vpc_id = aws_vpc.my-eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-eks-internet-gateway.id
  }
}

#create route table for private subnets
resource "aws_route_table" "my-eks-private-route-table" {
  vpc_id = aws_vpc.my-eks-vpc.id
  count  = length(var.private-subnets-cidr)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.my-eks-nat-gateway.*.id, count.index)
  }
}
#attach/associate route table to public subnet
resource "aws_route_table_association" "my-eks-public-subnets-rte-association" {
  count          = length(var.public-subnets-cidr)
  subnet_id      = element(aws_subnet.my-eks-public-subnets.*.id, count.index)
  route_table_id = aws_route_table.my-eks-public-route-table.id
}
#attach/associate route table to public subnet
resource "aws_route_table_association" "my-eks-private-subnets-rte-association" {
  count          = length(var.private-subnets-cidr)
  subnet_id      = element(aws_subnet.my-eks-private-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.my-eks-private-route-table.*.id, count.index)
}