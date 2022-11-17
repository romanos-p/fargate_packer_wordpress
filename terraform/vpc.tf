# The main VPC to deploy all the resources
resource "aws_vpc" "vpc" {
  cidr_block = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "vpc"
  }
}

# The main subnet where ECS lives
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1) # 10.0.1.0/24
  map_public_ip_on_launch = true
  availability_zone       = "${var.AWS_REGION}a"
}
# Private subnet to spin up the DB (opted with the public subnet for testing)
resource "aws_subnet" "subnet_priv_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2) # 10.0.2.0/24
  map_public_ip_on_launch = false
  availability_zone       = "${var.AWS_REGION}a"
}
# Another private subnet in a different az. This was required to create the subnet group below
resource "aws_subnet" "subnet_priv_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3) # 10.0.3.0/24
  map_public_ip_on_launch = false
  availability_zone       = "${var.AWS_REGION}b"
}

# A subnet group is required when no default VPC/subnet exist in a region
resource "aws_db_subnet_group" "subnet_group" {
  name       = "rds_sgroup"
  subnet_ids = [aws_subnet.subnet.id, aws_subnet.subnet_priv_a.id, aws_subnet.subnet_priv_b.id]
}

# Ingress and Egress for the internet for resources
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw"
  }
}

# Route table for the VPC
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate the public subnet user bu resources with the route table.
resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}