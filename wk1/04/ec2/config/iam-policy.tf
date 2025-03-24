# Get AWS account ID 
data "aws_caller_identity" "account" {}

/*
Info: 
Role: 
- IAM role for EC2 instances to allow scheduling and optimization
*/
resource "aws_iam_role" "ec2_instance_role" {
  name        = "ec2-optimizer-role"
  description = "Role for EC2 Optimization"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service : ["ec2.amazonaws.com"]
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount": "${data.aws_caller_identity.account.account_id}"
        }
        ArnLike = {
          "aws:SourceArn": "arn:aws:ec2:${var.region}:${data.aws_caller_identity.account.account_id}:instance/*"
        }
      }
    }]
  })
  # permissions_boundary = var.permissions_boundary_arn

  tags = {
    Name        = local.cost_tags.Name
    Environment = local.cost_tags.Environment
    Project     = local.cost_tags.Project
  }
}


/*
Info: 
Policy: 
- IAM policy defining permissions for EC2 scheduling and optimization
*/
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2-cost-optimization-policy"
  description = "Policy for EC2 cost optimization and scheduling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EC2InstanceManagement"
        Effect = "Allow"
        Action = [
        # Allow EventBridge to start/stop EC2 instance
        "ec2:StartInstances",
        "ec2:StopInstances"
        ]
        Resource = ["arn:aws:ec2:${var.region}:${data.aws_caller_identity.account.account_id}:instance/${aws_instance.server.id}"
        ]
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment": "dev",
            "ec2:ResourceTag/AutoShutdown": "true"
          }
        }
      },
      {
        Sid = "SpotInstanceManagement"
        Effect = "Allow"
        Action = [
        "ec2:RequestSpotInstances",
        "ec2:CancelSpotInstanceRequests",
        "ec2:DescribeSpotInstanceRequests", 
        "ec2:DescribeSpotPriceHistory",
        ]
        Resource = ["arn:aws:ec2:${var.region}:${data.aws_caller_identity.account.account_id}:instance:${aws_instance.server.id}"]
      },
      {
        Sid = "AutoScalingOps"
        Effect = "Allow"
        Action = [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        ]
        Resource = ["arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.account.account_id}:autoScalingGroup:*:autoScalingGroupName/ec2-autoscaling-group"]
      }, 
      {
        Sid = "ComputeOptimizerAccess"
        Effect = "Allow"
        Action = [
        "compute-optimizer:GetEnrollmentStatus", 
        "compute-optimizer:UpdateEnrollmentStatus",
        "compute-optimizer:GetRecommendations",
        ]
        Resource = ["arn:aws:ec2:${var.region}:${data.aws_caller_identity.account.account_id}:instance/${aws_instance.server.id}"]
      },
      {
        Sid = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms", 
          "cloudwatch:GetSchedule" 
        ]
        Resource = [
          "arn:aws:cloudwatch:${var.region}:${data.aws_caller_identity.account.account_id}:alarm:*",
          "arn:aws:scheduler:${var.region}:${data.aws_caller_identity.account.account_id}:schedule/ec2-autoscaling-group/*"
        ]
      }
    ]

    Condition = {
        StringEquals = {
          "ec2:ResourceTag/Environment" : "dev",
          "ec2:ResourceTag/AutoShutdown" : "true",
          "aws:SourceAccount" : data.aws_caller_identity.account.account_id
        }
        ArnLike = {
          "aws:SourceArn" : "arn:aws:scheduler:${var.region}:${data.aws_caller_identity.account.account_id}:schedule-group/*"
        }
      }
  })
  tags = {
    Name        = local.cost_tags.Name
    Environment = local.cost_tags.Environment
    Project     = local.cost_tags.Project
  }
}

/*
Info: 
Policy Attachment: 
- Attach the policy to the role
- IAM instance profile
*/

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-optimizer-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = local.cost_tags
}


resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_policy.arn
  role       = aws_iam_role.ec2_instance_role.name 
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role = aws_iam_role.ec2_instance_role.name
}
