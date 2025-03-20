/*
AMI: 
- required for every EC2 instance. Can be created from a 
stopped or running instance, or created anew. 
- here we use a data source to get the ID of an AMI
we would like to use. For this case, an ARM-based Amazon image
*/

data "aws_ami" "machine_image" {
  most_recent = true 
  owners = [ "amazon" ]
  
  filter {
    name = "name"
    values = [ "al2023-ami-2023*" ]
  }

  filter {
    name = "architecture"
    values = [ "arm64" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  tags = {
    "Name" = "caid-ec2-ami"
  }
}

/*
Spot fall back logic:
- add automated rollback from spot to on-demand using ASG
with mixed instance policies 
- implement instance scheduling to shut down non-critical
instances during off-peak hours
*/

// Defined EC2 spot instance
resource "aws_instance" "server" {
  ami = data.aws_ami.machine_image.id 
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }
  instance_type = "t2.micro"
  tags = {
    "Name" = "caid-ec2-spot"
  }
}

// ASG + mixed instance policies
resource "aws_launch_template" "template" {
  name_prefix = ""
  image_id = data.aws_ami.machine_image.id 
  instance_type = "m6g.medium"
}

resource "aws_autoscaling_group" "asg" {
  capacity_rebalance = true 
  desired_capacity = 3 # starting point
  max_size = 5 # allow scaling to 5 
  min_size = 1 # min to scale to 

  //
  health_check_grace_period = 300
  force_delete = true 
  termination_policies = [ "OldestInstance" ]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template.id 
      }
      override {
        instance_type = "t4g.medium"
        weighted_capacity = 1
      }

      override {
        instance_type = "m6g.medium"
        weighted_capacity = 2
      }
    }
  }
}

// Instance scheduling with EventBridge scheduler
resource "aws_scheduler_schedule" "start_ec2_instance" {
  name = "start-ec2-wednesdays"

  flexible_time_window {
    mode = "OFF"
  }

// Here we scheduled to start instance at 10 AM UTC
// we only need the instance for a lightweight task
// every Wednesday.
  schedule_expression = "cron(0 10 ? * WED *)"

  target {
    arn = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.ec2_scheduler_role.arn 

    input = jsonencode({
      InstanceIds = [
        aws_instance.server.id 
      ]
    })
  }
}

// Stop the EC2 instance every Friday at 5 PM UTC.
resource "aws_scheduler_schedule" "stop_ec2_instance" {
  name = "stop-ec2-on-fridays"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 17 ? * FRI *)"

  target {
    arn = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.ec2_scheduler_role.arn 

    input = jsonencode({
      InstanceIds = [
        aws_instance.server.id 
      ]
    })
  }
}


/*
Right sizing enhancements:
- utilize AWS compute optimizer recommedations
- implement dynamic instance selection based on cpu &
memory benchmarks
*/


/*
Auto-termination enhancemnets
- use cloudwatch alarms auto-termination
*/
