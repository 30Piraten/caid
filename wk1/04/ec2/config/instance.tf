# Locals for tags 
locals {
  cost_tags = {
    Name          = "ec2-cost-saver"
    Project       = "caid"
    CostCenter    = "caid-wk1"
    Environment   = "dev"
    AutoSchedule  = "true"
    CostOptimized = "true"
  }
}

/*
AMI: 
- required for every EC2 instance. Can be created from a 
stopped or running instance, or created anew. 
- here we use a data source to get the ID of an AMI
we would like to use. For this case, an ARM-based Amazon image
*/

data "aws_ami" "machine_image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  tags = {
    Environment = local.cost_tags.Environment
  }
}

# VPC definition
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 
  enable_dns_support = true 

  tags = local.cost_tags
}

resource "aws_subnet" "selected_subnet" {
  vpc_id = aws_vpc.default.id  
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  availability_zone = "us-east-1b"

  tags = local.cost_tags
}

resource "aws_internet_gateway" "net" {
  vpc_id = aws_vpc.default.id 

  tags = local.cost_tags
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net.id 
  }

  tags = local.cost_tags
}


# EC2 spot instance definition
resource "aws_instance" "server" {
  ami = data.aws_ami.machine_image.id
  subnet_id = aws_subnet.selected_subnet.id
  instance_market_options {
    market_type = var.market_type
    spot_options {
      max_price = 0.0031
    }
  }

  instance_type = var.instance_type

  tags = local.cost_tags
}


# Launch template for EC2 instance
resource "aws_launch_template" "template" {
  name_prefix   = var.name_prefix
  image_id      = data.aws_ami.machine_image.id
  # instance_type = var.instance_type

  instance_requirements {
    memory_mib {
      min = 1024
      max = 2085
    }
    vcpu_count {
      min = 1
      max = 2
    }
    instance_generations = ["current"]
    burstable_performance = "included"
  }

  tags = local.cost_tags
}
