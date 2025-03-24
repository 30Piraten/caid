# Capacity based auto scaling policy
# Scales up by adding 3 instances when capacity threshold is reached
# 5 minute cooldown period between scaling activities
resource "aws_autoscaling_policy" "ec2_capacity_based_policy" {
  name                   = var.ec2_capacity_based_policy_name
  scaling_adjustment     = 3
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Auto scaling policy to scale down idle instances
# Removes 1 instance at a time when idle
# 5 minute cooldown period between terminations
resource "aws_autoscaling_policy" "ec2_scale_down" {
  name                   = var.ec2_scale_down_policy_name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Cost based auto scaling policy
# Uses target tracking to maintain average CPU utilization at 70%
# Automatically scales capacity up or down to maintain target

# CPUUtilization is used in this cost-based scaling policy because:
# - It's a reliable proxy for instance utilization and cost efficiency
# - High CPU utilization (>70%) indicates the instance is being used effectively
# - Low CPU utilization suggests over-provisioning and wasted costs
# - Using CPU metrics helps maintain optimal cost-to-performance ratio
# - AWS charges the same for an idle instance as a busy one, so maintaining
#   target CPU utilization helps optimize costs
resource "aws_autoscaling_policy" "ec2_cost_based_policy" {
  name                   = var.ec2_cost_based_policy_name
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
# Scales down to 1-2 instances at midnight (00:00)
resource "aws_autoscaling_schedule" "scaling_down_night" {
  scheduled_action_name = var.scaling_down_schedule_name
  min_size = 1
  max_size = 2
  desired_capacity = 1
  recurrence = "0 0 * * *"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Scales up to 1-3 instances at 8am (08:00)
resource "aws_autoscaling_schedule" "scaling_up_morning" {
  scheduled_action_name = var.scaling_up_morning_schedule_name
  min_size = 1
  max_size = 3
  desired_capacity = 2
  recurrence = "0 8 * * *"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}

# Auto scaling group for EC2 instances
# Manages a mix of spot and on-demand instances
# Enables automatic rebalancing of Spot Instances
resource "aws_autoscaling_group" "ec2_asg" {
  capacity_rebalance = true  
  # availability_zones = [ "us-east-1b" ]
  vpc_zone_identifier = [ aws_subnet.selected_subnet.id ]
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
      # spot_instance_pools                      = 3    
      on_demand_allocation_strategy            = "prioritized"
      spot_max_price                          = "0.0031" 
    }

  launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template.id
      }
      # t4g.medium instances with weight 1
      override {
        instance_type     = "t4g.medium"
        weighted_capacity = 1
      }

      # m6g.medium instances with weight 2 (counts as 2 units of capacity)
      override {
        instance_type     = "m6g.medium"
        weighted_capacity = 2
      }
    }
  }
  tag {
    key                 = local.cost_tags.Name
    value               = local.cost_tags.Environment
    propagate_at_launch = true  # Propagate tags to launched instances
  }
}
