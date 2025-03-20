resource "aws_iam_role" "ec2_scheduler_role" {
name = "ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
  })
}