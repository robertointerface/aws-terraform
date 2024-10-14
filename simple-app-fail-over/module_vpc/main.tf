/*
Create all the Networking components:
1 - VPC
2 - two public subnets.
3 - two private subnets.
4 - Internet Gateway at the public subnets.
5 - NAT Gateways at the public subnets that take traffic from the private subnets.
6 - Security group for the Load balancer that takes all input traffic.
7 - Security group for the EC2s created by the Auto-Scaling group that only accept http traffic (prot 80) from the
load balancer.
8 - Required Route tables, one for public and one for private.
*/
provider "aws" {
  region = var.region
}
resource "aws_vpc" "vpc_a1" {
  cidr_block                       = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "VPC-A1"
  }
}
resource "aws_subnet" "public_subnet_A" {
  vpc_id            = aws_vpc.vpc_a1.id
  cidr_block        = "10.1.${var.subnet_increase * 0}.0/${var.subnet_submask}"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.vpc_a1.ipv6_cidr_block, 4, 0)
  availability_zone = "${var.region}a"
  tags = {
    Name = "public_subnet_a"
  }
}
resource "aws_subnet" "public_subnet_B" {
  vpc_id            = aws_vpc.vpc_a1.id
  ipv6_cidr_block   = cidrsubnet(aws_vpc.vpc_a1.ipv6_cidr_block, 4, 1)
  cidr_block        = "10.1.${var.subnet_increase * 1}.0/${var.subnet_submask}"
  availability_zone = "${var.region}b"
  tags = {
    Name = "public_subnet_b"
  }
}
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.vpc_a1.id
  cidr_block        = "10.1.${var.subnet_increase * 2}.0/${var.subnet_submask}"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.vpc_a1.ipv6_cidr_block, 4, 2)
  availability_zone = "${var.region}a"
  tags = {
    Name = "private_subnet_a"
  }
}
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.vpc_a1.id
  cidr_block        = "10.1.${var.subnet_increase * 3}.0/${var.subnet_submask}"
  ipv6_cidr_block   = cidrsubnet(aws_vpc.vpc_a1.ipv6_cidr_block, 4, 3)
  availability_zone = "${var.region}b"
  tags = {
    Name = "private_subnet_b"
  }
}
resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.vpc_a1.id
  tags = {
    Name = "vpc_a1_gw"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_a1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }
  route {
    cidr_block = aws_vpc.vpc_a1.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.vpc_a1.ipv6_cidr_block
    gateway_id = "local"
  }
  tags = {
    Name = "public_route_table"
  }
}
resource "aws_eip" "nat" {
  domain   = "vpc"
}
resource "aws_nat_gateway" "public_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_A.id
  tags = {
    Name = "gw NAT"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.terraform_gw]
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_a1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_nat.id
  }
  route {
    cidr_block = aws_vpc.vpc_a1.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.vpc_a1.ipv6_cidr_block
    gateway_id = "local"
  }
  tags = {
    Name = "private_route_table"
  }
}
resource "aws_route_table_association" "route_public_a_to_public_table" {
  subnet_id      = aws_subnet.public_subnet_A.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "route_public_b_to_public_table" {
  subnet_id      = aws_subnet.public_subnet_B.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "route_private_a_to_private_table" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "route_private_b_to_private_table" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_security_group" "load_balancer_SG" {
  name        = "load_balancer_sg"
  description = "allow ssh, http and https for load balancer in, allow all out"
  vpc_id      = aws_vpc.vpc_a1.id
}
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_all_alb" {
  security_group_id = aws_security_group.load_balancer_SG.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "outbound_allow_all_alb" {
  security_group_id = aws_security_group.load_balancer_SG.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_security_group" "ec2_instance_asg" {
  name        = "ec2_instance_sg"
  description = "allow ssh, http and https for load balancer in, allow all out"
  vpc_id      = aws_vpc.vpc_a1.id
}
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_https_asg" {
  security_group_id = aws_security_group.ec2_instance_asg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.load_balancer_SG.id
}
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_http_asg" {
  security_group_id = aws_security_group.ec2_instance_asg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.load_balancer_SG.id
}
resource "aws_vpc_security_group_egress_rule" "outbound_allow_all_asg" {
  security_group_id = aws_security_group.ec2_instance_asg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
