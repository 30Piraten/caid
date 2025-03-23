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

# EC2 spot instance definition
resource "aws_instance" "server" {
  ami = data.aws_ami.machine_image.id
  instance_market_options {
    market_type = var.market_type
    spot_options {
      max_price = 0.0031
    }
  }

  instance_type = var.instance_type

  tags = {
    Name         = local.cost_tags.Name
    Environment  = local.cost_tags.Environment
    AutoSchedule = local.cost_tags.AutoSchedule
    Project      = local.cost_tags.Project
    CostCenter   = local.cost_tags.CostCenter
  }
}


# Launch template for EC2 instance
resource "aws_launch_template" "template" {
  name_prefix   = var.name_prefix
  image_id      = data.aws_ami.machine_image.id
  instance_type = var.instance_type

  instance_requirements {
    memory_mib {
      min = 1024
      max = 4096
    }
    vcpu_count {
      min = 1
      max = 2
    }
    instance_generations = ["current"]
    burstable_performance = "included"
  }
}