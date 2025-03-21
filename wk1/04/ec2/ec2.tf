locals {
  cost_tags = {
    Name          = "ec2-cost-saver"
    Project       = "caid"
    CostCenter    = "caid-wk1"
    Environment   = var.env
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

/*
Defined EC2 spot instance
*/
resource "aws_instance" "server" {
  ami = data.aws_ami.machine_image.id
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0031
    }
  }

  instance_type = "t4g.micro"

  tags = {
    Name         = local.cost_tags.Name
    Environment  = local.cost_tags.Environment
    AutoSchedule = local.cost_tags.AutoSchedule
    Project      = local.cost_tags.Project
    CostCenter   = local.cost_tags.CostCenter
  }
}

/*
ASG + mixed instance policies
*/
resource "aws_launch_template" "template" {
  name_prefix   = "launch-template"
  image_id      = data.aws_ami.machine_image.id
  instance_type = "t4g.micro"

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

/*
Auto-scaling policies + ASG
*/

# Capacity based auto scaling policy
resource "aws_autoscaling_policy" "ec2_scaling_policy" {
  name                   = "ec2-scaling-policy"
  scaling_adjustment     = 3
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Auto scaling policy to scale down idle instances
resource "aws_auto_scaling_policy" "ec2_scale_down" {
  name                   = "ec2-terminate-idle-instance"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Cost based auto scaling policy
resource "aws_auto_scaling_policy" "ec2_cost_based_policy" {
  name                   = "ec2-cost-based-policy"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = 70.0
    customized_metric_specification {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      statistic   = "Average"
    }
  }
}

# Auto scaling schedule
resource "aws_autoscaling_schedule" "scaling_down_night" {
  scheduled_action_name = "scale-down-night"
  min_size = 1
  max_size = 2
  desired_capacity = 1
  recurrence = "0 0 * * *"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg
}

resource "aws_autoscaling_schedule" "scaling_up_morning" {
  scheduled_action_name = "scale-up-morning"
  min_size = 1
  max_size = 3
  desired_capacity = 2
  recurrence = "0 8 * * *"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Auto scaling group for EC2 instances
resource "aws_autoscaling_group" "ec2_asg" {
  capacity_rebalance = true
  # desired_capacity   = 3 # starting point
  max_size = 5 
  min_size = 1 

  health_check_grace_period = 300
  force_delete              = true
  termination_policies      = ["OldestInstance"]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
      spot_instance_pools                      = 3
      on_demand_allocation_strategy            = "prioritized"
      spot_max_price                           = "0.0031"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template.id
      }
      override {
        instance_type     = "t4g.medium"
        weighted_capacity = 1
      }

      override {
        instance_type     = "m6g.medium"
        weighted_capacity = 2
      }
    }
  }
  tag {
    key                 = local.cost_tags.Name
    value               = local.cost_tags.Name
    propagate_at_launch = true
  }
}

/*
Instance scheduling with EventBridge scheduler
*/
resource "aws_scheduler_schedule" "start_ec2_instance" {
  name = "start-ec2-wednesdays"

  flexible_time_window {
    mode = "OFF"
  }

  // Here we scheduled to start the instance at 10 AM UTC
  // we only need the instance for a lightweight task
  // every Wednesday.
  schedule_expression = "cron(0 10 ? * WED *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.ec2_scheduler_role.arn

    input = jsonencode({
      InstanceIds = [
        aws_instance.server.id
      ]
    })
  }
}

/* 
Stop the EC2 instance every Friday at 5 PM UTC.
*/
resource "aws_scheduler_schedule" "stop_ec2_instance" {
  name = "stop-ec2-on-fridays"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 17 ? * FRI *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
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
  This refers to using AWS Compute Optimizer service which analyzes instance metrics 
  and provides recommendations for optimal instance types based on workload patterns

- implement dynamic instance selection based on cpu & memory benchmarks
  This suggests implementing logic to automatically select instance types
  based on actual CPU and memory utilization metrics, rather than using
  fixed instance types. This helps ensure instances are properly sized
  for the workload.
*/

resource "aws_computeoptimizer_enrollment_status" "ec2_optimiser" {
  status = "Active"
}

resource "aws_computeoptimizer_recommendation_preferences" "ec2_preference" {
  resource_type = "Ec2Instance"
  scope {
    name  = "Instance"
    value = aws_instance.server.id
  }

  enhanced_infrastructure_metrics = "Active"
  external_metrics_preference {
    source = "Datadog"
  }

  preferred_resource {
    include_list = ["t4g.medium", "m6g.medium"]
    name         = "Ec2InstanceTypes"
  }
}


/*
Auto-termination enhancements:
- This refers to automatically terminating EC2 instances based on CloudWatch alarms
- CloudWatch alarms can monitor metrics like CPU utilization, memory usage, etc.
- When alarm thresholds are breached, instances can be automatically terminated
- This helps optimize costs by removing underutilized or problematic instances
- Common use cases:
  - Terminate instances with consistently low CPU usage
  - Remove instances that are unresponsive or unhealthy
  - Scale down capacity during low demand periods
*/

# CloudWatch alarm for CPU utilization 
resource "aws_cloudwatch_metric_alarm" "ec2_cloudwatch_alarm" {
  alarm_name          = "caid-ec2-cloudwatch-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
  }

  alarm_description = "Alarm to monitor CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.ec2_scaling_policy.arn]
}

# Cloudwatch alarm for idle instance termination
resource "aws_cloudwatch_metric_alarm" "ec2_cloudwatch_terminate_alarm" {
  alarm_name          = "caid-ec2-cloudwatch-terminate-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "24"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"

  alarm_actions = [aws_autoscaling_policy.ec2_scaling_policy.ec2_scale_down.arn]
}

# Cloudwatch alarm for cost monitoring
resource "aws_cloudwatch_metric_alarm" "ec2_cloudwatch_cost_alarm" {
  alarm_name          = "caid-ec2-cloudwatch-cost-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  alarm_actions = [aws_autoscaling_policy.ec2_cost_based_policy.arn]
}

# Cost monitoring 
resource "aws_budgets_budget" "ec2_cost" {
  name = "ec2-monthly-budget"
  budget_type = "COST"
  limit_amount = "200"
  limit_unit = "USD"
  time_unit = "MONTHLY"

  cost_filter {
    name = "Service"
    values = ["AmazonEC2"]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold = 80 
    threshold_type = "PERCENTAGE"
    notification_type = "ACTUAL"
  }
}