resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts"
}

# Cost monitoring with AWS Budgets
resource "aws_budgets_budget" "ec2_budgets" {
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

    subscriber_sns_topic_arns = [ aws_sns_topic.budget_alerts.arn ]
  }
  
}
