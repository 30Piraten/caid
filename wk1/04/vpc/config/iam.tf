data "aws_caller_identity" "current" {}

# IAM role for NAT Gateway
resource "aws_iam_role" "nat_gateway_role" {
  name = "nat-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for NAT Gateway
resource "aws_iam_role_policy" "nat_gateway_policy" {
  name = "nat-gateway-policy"
  role = aws_iam_role.nat_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstances",
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface"
        ]
        Resource = [
   "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/${aws_vpc.network.id}",
   "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
 ]      }
    ]
  })
}