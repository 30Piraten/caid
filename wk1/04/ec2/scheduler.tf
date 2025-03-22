/*
- Instance scheduling with EventBridge scheduler
- This configuration sets up two EventBridge scheduler rules to automatically start and stop an EC2 instance
- The scheduler uses AWS SDK integration to call EC2 APIs directly
*/
resource "aws_scheduler_schedule" "start_ec2_instance" {
  name = "start-ec2-wednesdays"

  flexible_time_window {
    mode = "OFF"
  }

  /* 
  Here we scheduled to start the instance on Wednesday at 10 AM UTC
  Cron expression breakdown:
  - 0 - At minute 0
  - 10 - At 10:00 AM
  - ? - No specific day of month
  - * - Every month
  - WED - On Wednesday
  - * - Every year
  */
  schedule_expression = "cron(0 10 ? * WED *)"

  # Target configuration specifies what action to take when scheduler triggers
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
This helps save costs by ensuring instances don't run over weekends.
*/
resource "aws_scheduler_schedule" "stop_ec2_instance" {
  name = "stop-ec2-on-fridays"

  flexible_time_window {
    mode = "OFF"
  }

  # Cron expression to run at 5 PM UTC every Friday
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
