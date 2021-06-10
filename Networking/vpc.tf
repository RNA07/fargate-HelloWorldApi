terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}
provider "aws" {
  region = var.region
}

# VPC Network Setup
resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
   tags = {
    Name = "${var.app_name}/${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main_vpc.id}"
   tags = {
    Name = "${var.app_name}/${var.environment}"
  }
}

# Public Subnet
resource "aws_subnet" "Public-Subnet" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "Private-Subnet" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "Private Subnet"
  }
}

# Netgateway
resource "aws_eip" "nat" {
  vpc=true
  
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.Public-Subnet.id}"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "Nat_Gateway"
  }
}

# Route for Private Subnet with Nat gateway
resource "aws_route_table" "private_route" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }


  tags = {
    Name = "fordatabase"
  }
}

resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.Private-Subnet.id
  route_table_id = aws_route_table.private_route.id
}

# Route table
resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "${var.app_name}/${var.environment}"
  }
}

# Route table association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.Public-Subnet.id
  route_table_id = aws_route_table.main.id
}

# create a security group for VPC link
resource "aws_security_group" "main" {
  name        = "VPC_Link_SG"
  description = "Allow hhtp"
  vpc_id      = "${aws_vpc.main_vpc.id}"

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }   

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}/${var.environment}"
  }
}

# Subnet Ids
data "aws_subnet_ids" "main" {
  vpc_id = aws_vpc.main_vpc.id
  depends_on = [aws_subnet.Public-Subnet]
}

# VPC Link
resource "aws_apigatewayv2_vpc_link" "main" {
  name        = "${var.app_name}-${var.environment}"
  subnet_ids  = data.aws_subnet_ids.main.ids
  security_group_ids = [aws_security_group.main.id] 
}

# Fargate Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.app_name}-${var.environment}"
  description = "Private DNS Namespace"
  vpc         = aws_vpc.main_vpc.id
}

