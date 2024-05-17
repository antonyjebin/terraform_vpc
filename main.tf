terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

#create a own vpc
resource "aws_vpc" "EKS_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "EKS_VPC"
  }
}

#create public subnet
resource "aws_subnet" "EKS_Public_Subnet" {
  vpc_id     = aws_vpc.EKS_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "EKS_Public_Subset"
  }
}

#create private subnet
resource "aws_subnet" "EKS_Private_Subnet" {
  vpc_id     = aws_vpc.EKS_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "EKS_Private_Subnet"
  }
}

#create internet gateway and attached with our VPC
resource "aws_internet_gateway" "EKS_Internet_Gateway" {
  vpc_id = aws_vpc.EKS_VPC.id

  tags = {
    Name = "EKS_Internet_Gateway"
  }
}

#create route table for public subnet
resource "aws_route_table" "EKS_Public_RouteTable" {
  vpc_id = aws_vpc.EKS_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.EKS_Internet_Gateway.id
  }

  tags = {
    Name = "EKS_Public_RouteTable"
  }
}

#associate route table with public route table
resource "aws_route_table_association" "EKS_Public_RouteTable_Association" {
  subnet_id      = aws_subnet.EKS_Public_Subnet.id
  route_table_id = aws_route_table.EKS_Public_RouteTable.id
}

resource "aws_eip" "EKS_ElasticIP" {
  domain   = "vpc"
  tags = {
    Name = "EKS_ElasticIP"
  }
}

#create NAT gateway
resource "aws_nat_gateway" "EKS_NAT" {
  allocation_id = aws_eip.EKS_ElasticIP.id
  subnet_id     = aws_subnet.EKS_Public_Subnet.id

  tags = {
    Name = "EKS_NAT"
  }
}

#create route table for private subnet
resource "aws_route_table" "EKS_Private_RouteTable" {
  vpc_id = aws_vpc.EKS_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.EKS_NAT.id

  }

  tags = {
    Name = "EKS_Private_RouteTable"
  }
}

#create private route table association
resource "aws_route_table_association" "EKS_Private_RouteTable_Association" {
  subnet_id      = aws_subnet.EKS_Private_Subnet
  route_table_id = aws_route_table.EKS_Private_RouteTable
}



