resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true   # fixed: was "hostname" not "hostnames"

  tags = {
    Name = var.name
  }
}

# ── PUBLIC SUBNETS ──────────────────────────────────────
# Load Balancer lives here. Has a public IP.
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_public_cidr[count.index]
  availability_zone = var.azs[count.index]

  # Automatically assign a public IP to any instance launched here
  
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"   # tells AWS ALB which subnets to use
  }
}

# ── PRIVATE SUBNETS ─────────────────────────────────────
# EKS nodes live here. No public IP. Reach internet via NAT.
resource "aws_subnet" "private" {   # fixed: was missing closing " on "aws_subnet"
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_private_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                              = "${var.name}-private-${count.index + 1}"  # fixed: was saying "public"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ── ISOLATED SUBNETS ────────────────────────────────────
# RDS lives here. No internet route at all — not even outbound.
resource "aws_subnet" "isolated" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id   # fixed: was vpc_ids
  cidr_block        = var.subnet_isolated_cidr[count.index]   # fixed: typo isolaed
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-isolated-${count.index + 1}"   # fixed: typo isolaed
  }
}

# ── INTERNET GATEWAY ────────────────────────────────────
# The door between your VPC and the public internet.
# Only public subnets use this.
resource "aws_internet_gateway" "platform_igw" {   # fixed: hyphen → underscore
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.name}-igw" }
}

# ── ELASTIC IPs FOR NAT ─────────────────────────────────
# Each NAT Gateway needs a fixed public IP address.
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
}

# ── NAT GATEWAYS ────────────────────────────────────────
# Sit in PUBLIC subnets. Allow private subnet resources
# to reach the internet outbound (to pull images etc.)
# but nothing from internet can reach them inbound.
resource "aws_nat_gateway" "natgateway" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id   # NAT goes in PUBLIC subnet

  tags = { Name = "${var.name}-nat-${count.index + 1}" }   # fixed: missing =
}

# ── PUBLIC ROUTE TABLE ──────────────────────────────────
# Rule: all traffic (0.0.0.0/0) goes to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform_igw.id   # fixed: missing .id, hyphen→underscore
  }

  tags = { Name = "${var.name}-public-rt" }   # fixed: unclosed string
}

# ── PRIVATE ROUTE TABLES ────────────────────────────────
# Rule: all traffic goes to the NAT Gateway (not IGW)
# One per AZ so if one NAT fails, only that AZ is affected
resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.vpc.id   # fixed: was aws_vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway[count.index].id   # fixed: was gateway_id
  }

  tags = {
    Name = "${var.name}-private-rt-${count.index + 1}"
  }
}

# ── ROUTE TABLE ASSOCIATIONS ────────────────────────────
# This is what actually connects a subnet to a route table.
# Without this, the route table exists but does nothing.

resource "aws_route_table_association" "public" {   # fixed: "associated" → "association"
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id   # fixed: was referencing variable
  route_table_id = aws_route_table.public.id            # fixed: was "route_table"
}

resource "aws_route_table_association" "private" {   # fixed: "associated" → "association"
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id   # fixed: was referencing variable
  route_table_id = aws_route_table.private[count.index].id
}