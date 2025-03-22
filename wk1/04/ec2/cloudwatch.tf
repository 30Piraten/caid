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
