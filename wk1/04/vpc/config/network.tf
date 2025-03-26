# Define local variables for consistent resource tagging and network configuration
locals {
  # Common tags to be applied to all resources
  cost_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform",
    CostCenter  = "${var.project_name}-vpc-cost"
  }

  # Dynamic subnet calculation
  subnet_newbits = 4
  # Calculate CIDR blocks for private and public subnets
  # Private subnets use first 3 /20 blocks
  private_subnets = {
    for index, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, local.subnet_newbits, index)
  }
  # Public subnets use next 3 /20 blocks after private subnets
  public_subnets = {
    for index, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, local.subnet_newbits, index + length(var.availability_zones))
  }
}

# Data source to get current AWS region name
data "aws_region" "current" {}

# Create the main VPC
resource "aws_vpc" "network" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Create Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.network.id
  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Create private subnets in each AZ for internal resources
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.network.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.cost_tags, {
    Name = "private-${each.key}"
    Tier = "Private"
  })
}

# Create public subnets in each AZ for internet-facing resources
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.network.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true # Auto-assign public IPs to instances

  tags = merge(local.cost_tags, {
    Name = "public-${each.key}"
    Tier = "Public"
  })
}

# Create route tables for private subnets (one per AZ)
resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.network.id

  # Local route is automatically added by AWS
  tags = merge(local.cost_tags, {
    Name             = "${var.project_name}-private-rt-${each.key}"
    AvailabilityZone = each.key
  })
}

# Create single route table for all public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.network.id
  route {
    cidr_block = "0.0.0.0/0" # Route all internet traffic through IGW
    gateway_id = aws_internet_gateway.gateway.id
    nat_gateway_id = aws_nat_gateway.nat[keys(local.public_subnets)[0]].id
  }
  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associate private subnets with their respective route tables
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (for private subnet internet access)
resource "aws_eip" "ip" {
  domain = "vpc"

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  for_each = local.public_subnets
  allocation_id = aws_eip.ip[each.key].id 
  subnet_id     = each.value.id 

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-nat-gw"
  })
}

# VPC Endpoints for cost optimization
resource "aws_security_group" "endpoint_security" {
  name        = "${var.project_name}-endpoint-sg"
  description = "Security group for VPC service endpoints"
  vpc_id      = aws_vpc.network.id

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-sg"
  })
}

# Allow all outbound traffic within VPC CIDR range
resource "aws_vpc_security_group_egress_rule" "endpoint_security" {
  security_group_id = aws_security_group.endpoint_security.id
  from_port = 0
  to_port = 0 
  ip_protocol = "-1"
  cidr_ipv4 = var.vpc_cidr

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-egress-rule"
  })
}

# Allow HTTPS inbound from within VPC to endpoints
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.endpoint_security.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-ingress-rule"
  })
}

# S3 Gateway Endpoint for private subnet access to S3
resource "aws_vpc_endpoint" "s3" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.network.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [for rt in values(aws_route_table.private) : rt.id]
  )
  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-s3-endpoint"
  })
}

# ECR Docker registry endpoint
resource "aws_vpc_endpoint" "ecr_docker" {
  for_each = local.private_subnets

  vpc_id              = aws_vpc.network.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private[each.key].id]
  security_group_ids  = [aws_security_group.endpoint_security.id]
  private_dns_enabled = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-ecr-docker-${each.key}"
  })
}

# ECR API endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  for_each = local.private_subnets

  vpc_id              = aws_vpc.network.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private[each.key].id]
  security_group_ids  = [aws_security_group.endpoint_security.id]
  private_dns_enabled = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-ecr-api-${each.key}"
  })
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  for_each = local.private_subnets

  vpc_id              = aws_vpc.network.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private[each.key].id]
  security_group_ids  = [aws_security_group.endpoint_security.id]
  private_dns_enabled = true

  tags = merge(local.cost_tags, {
    Name = "${var.project_name}-logs-${each.key}"
  })
}


