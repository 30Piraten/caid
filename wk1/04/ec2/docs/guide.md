# AWS Infrastructure Cost Optimization with EC2, Lambda, and S3

This project implements a comprehensive AWS infrastructure setup focused on cost optimization and automated resource management. It combines EC2 instance scheduling, auto-scaling strategies, and Lambda functions to provide an efficient and cost-effective cloud infrastructure solution.

The infrastructure leverages AWS best practices for cost optimization including Spot instances, auto-scaling groups with mixed instance policies, scheduled start/stop times, and AWS Compute Optimizer integration. The system automatically manages resources based on utilization patterns and implements sophisticated monitoring and alerting through CloudWatch. Key features include automatic instance termination for idle resources, cost-based scaling policies, and scheduled operations for non-production workloads.

## Repository Structure
```
.
└── wk1/04/
    ├── ec2/                    # EC2 infrastructure configuration
    │   ├── anatomy.md         # EC2 infrastructure documentation
    │   ├── ec2.tf            # EC2 instance and ASG configuration
    │   ├── iam.tf            # IAM roles and policies for EC2
    │   └── variable.tf       # Infrastructure variables definition
    ├── lambda/                # Lambda function configuration
    │   ├── api.go            # Simple Go Lambda function
    │   └── lambda.tf         # Lambda infrastructure setup
    └── s3/                    # S3 bucket configuration
        └── s3.tf             # S3 bucket definition
```

## Usage Instructions
### Prerequisites
- AWS CLI installed and configured
- Terraform >= 0.12
- Go >= 1.16 (for Lambda function development)
- AWS account with appropriate permissions
- IAM permissions for:
  - EC2 management
  - Lambda function deployment
  - S3 bucket creation
  - IAM role/policy management
  - CloudWatch metrics and alarms
  - EventBridge scheduler

### Installation

1. Clone the repository and navigate to the project directory:
```bash
git clone <repository-url>
cd wk1/04
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review and modify variables in `ec2/variable.tf` as needed:
```hcl
variable "region" {
  default = "us-east-1"
}
variable "env" {
  default = "dev"
}
```

4. Deploy the infrastructure:
```bash
terraform plan
terraform apply
```

### Quick Start

1. Deploy EC2 Infrastructure:
```bash
cd ec2
terraform apply
```

2. Deploy Lambda Function:
```bash
cd ../lambda
terraform apply
```

3. Create S3 Bucket:
```bash
cd ../s3
terraform apply
```

### More Detailed Examples

1. EC2 Instance Scheduling:
```hcl
# Schedule EC2 instance start (Wednesdays at 10 AM UTC)
resource "aws_scheduler_schedule" "start_ec2_instance" {
  name = "start-ec2-wednesdays"
  schedule_expression = "cron(0 10 ? * WED *)"
}
```

2. Auto-Scaling Configuration:
```hcl
# Create auto-scaling policy based on CPU utilization
resource "aws_autoscaling_policy" "ec2_cost_based_policy" {
  name = "ec2-cost-based-policy"
  target_tracking_configuration {
    target_value = 70.0
    customized_metric_specification {
      metric_name = "CPUUtilization"
    }
  }
}
```

### Troubleshooting

1. EC2 Instance Launch Issues
- Problem: Spot instance requests failing
- Solution: 
  ```bash
  aws ec2 describe-spot-instance-requests --region us-east-1
  ```
  Check if max price is below current spot price

2. Auto-Scaling Issues
- Enable detailed monitoring:
  ```bash
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "your-asg" --enable-metrics-collection
  ```
- Check CloudWatch metrics:
  ```bash
  aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization
  ```

3. Lambda Function Issues
- View Lambda logs:
  ```bash
  aws logs get-log-events --log-group-name /aws/lambda/your-function-name
  ```

## Data Flow

The infrastructure implements a cost-optimized workflow where EC2 instances are automatically managed based on utilization and scheduling patterns.

```ascii
                                     +----------------+
                                     |  CloudWatch    |
                                     |   Alarms      |
                                     +-------+--------+
                                             |
                                             v
+----------------+    +--------------+    +--+-----------+
|   EventBridge  |--->|    Auto     |--->|    EC2       |
|   Scheduler    |    |   Scaling   |    | Instances    |
+----------------+    +--------------+    +-------------+
                                             |
                                             v
                                     +----------------+
                                     | Compute        |
                                     | Optimizer      |
                                     +----------------+
```

Key Component Interactions:
1. EventBridge Scheduler triggers instance start/stop based on defined schedule
2. Auto Scaling Group manages instance lifecycle based on policies
3. CloudWatch monitors instance metrics and triggers scaling actions
4. Compute Optimizer provides instance type recommendations
5. IAM roles and policies control access and permissions
6. Lambda function operates independently for specific tasks
7. S3 bucket provides storage capabilities when needed

## Infrastructure

![Infrastructure diagram](./docs/infra.svg)

### Lambda
- Function: Simple Go Lambda function that prints "Milch oder Kaffe?"
- Runtime: Go 1.x
- Trigger: Manual/API Gateway

### EC2
- Instance Type: t4g.micro (ARM-based)
- Auto Scaling Group with mixed instance policy
- Spot Instance configuration with max price of $0.0031
- Scheduled operations:
  - Start: Wednesdays at 10 AM UTC
  - Stop: Fridays at 5 PM UTC

### IAM
- Role: ec2-optimizer-role
- Policies:
  - EC2 instance management
  - Spot instance operations
  - Auto Scaling operations
  - CloudWatch metrics access
  - Compute Optimizer access

### CloudWatch
- CPU Utilization alarm
- Cost monitoring alarm
- Instance termination alarm