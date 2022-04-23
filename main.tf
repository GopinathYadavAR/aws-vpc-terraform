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
  cidr_block =  var.main-vpc-cidr
  instance_tenancy = "default"
}
resource "aws_eip" "nateIP" {
  vpc = true
}

# create the internet gateway and attach to vpc
resource "aws_internet_gateway" "my-eks-internet-gateway" {
  vpc_id = aws_vpc.my-eks-vpc.id
}

#create the public subnet
resource "aws_subnet" "my-eks-public-subnets" {
  vpc_id = aws_vpc.my-eks-vpc.id
  cidr_block = var.public-subnets
}
# create the private subnet
resource "aws_subnet" "my-eks-private-subnets" {
  vpc_id = aws_vpc.my-eks-vpc.id
  cidr_block = var.private-subnets
}
#create the nat gateway and attach to vpc
resource "aws_nat_gateway" "my-eks-nat-gateway" {
  allocation_id = aws_eip.nateIP.id
  subnet_id = aws_subnet.my-eks-public-subnets.id
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
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-eks-nat-gateway.id
  }
}
#attach/associate route table to public subnet
resource "aws_route_table_association" "my-eks-public-subnets-rte-association" {
   subnet_id = aws_subnet.my-eks-public-subnets.id
  route_table_id = aws_route_table.my-eks-public-route-table.id
}
#attach/associate route table to public subnet
resource "aws_route_table_association" "my-eks-private-subnets-rte-association" {
  subnet_id = aws_subnet.my-eks-private-subnets.id
  route_table_id = aws_route_table.my-eks-private-route-table.id
}