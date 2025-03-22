# AWS EC2 Cost Optimization Infrastructure

This project provides a comprehensive AWS infrastructure setup for EC2 instance cost optimization through automated scheduling, scaling, and monitoring. It combines spot instances, auto-scaling, and intelligent scheduling to minimize EC2 costs while maintaining performance.

The infrastructure uses Terraform to implement several cost-saving strategies including:
- Automated instance scheduling with EventBridge to start instances on Wednesdays and stop them on Fridays
- AWS Compute Optimizer integration for right-sizing recommendations
- Auto-scaling based on CPU utilization metrics
- Spot instance management with price constraints
- Budget monitoring and alerting
- CloudWatch alarms for performance and cost monitoring

## Repository Structure
```
.
└── wk1/04/ec2/
    ├── autoscaling.tf         # Auto Scaling Group configuration and policies
    ├── budgets.tf            # AWS Budget setup for EC2 cost monitoring
    ├── cloudwatch.tf         # CloudWatch alarms for CPU and cost monitoring
    ├── iam-policy.tf         # IAM roles and policies for EC2 optimization
    ├── instance.tf           # EC2 instance and launch template configuration
    ├── optimizer.tf          # AWS Compute Optimizer setup
    ├── outputs.tf            # Output definitions for EC2 instance ID
    ├── provider.tf           # AWS provider configuration
    ├── scheduler.tf          # EventBridge scheduler for instance management
    └── variable.tf           # Input variables for configuration
```

## Usage Instructions
### Prerequisites
- AWS CLI installed and configured
- Terraform v1.0.0 or later
- AWS account with appropriate permissions
- IAM user with programmatic access
- AWS profile configured with name "tf-user"

### Installation

1. Clone the repository and navigate to the EC2 directory:
```bash
cd wk1/04/ec2
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the configuration:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

### Quick Start

1. Configure the required variables in a `terraform.tfvars` file:
```hcl
region = "us-east-1"
env = "dev"
instance_type = "t4g.micro"
market_type = "spot"
```

2. Apply the configuration to create the infrastructure:
```bash
terraform apply -var-file="terraform.tfvars"
```

### More Detailed Examples

1. Creating a spot instance with custom tags:
```hcl
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
    Name = "ec2-cost-saver"
    Environment = "dev"
  }
}
```

### Troubleshooting

1. Spot Instance Request Issues
- Problem: Spot instance requests failing
- Solution: Check spot price history and adjust max price:
```bash
aws ec2 describe-spot-price-history --instance-types t4g.micro --start-time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

2. Auto Scaling Issues
- Problem: Instances not scaling as expected
- Solution: Review CloudWatch metrics and alarms:
```bash
aws cloudwatch describe-alarms --alarm-names "caid-ec2-cloudwatch-cpu-alarm"
```

3. Scheduler Issues
- Problem: Instances not starting/stopping on schedule
- Solution: Verify EventBridge scheduler rules:
```bash
aws scheduler list-schedules
```

## Data Flow
The infrastructure implements a cost optimization workflow that monitors, manages, and adjusts EC2 resources based on usage patterns and defined thresholds.

```ascii
                                    +----------------+
                                    |  EventBridge   |
                                    |   Scheduler    |
                                    +--------+-------+
                                             |
                                             v
+----------------+    +--------------+    +--+----------+    +------------------+
|   CloudWatch   |--->|              |    |            |    |  Auto Scaling    |
|    Alarms      |    | EC2 Instance |<---| CloudWatch |<---|     Group        |
+----------------+    |              |    |  Metrics   |    |                  |
                     +--------------+    +------------+    +------------------+
                           ^                                        ^
                           |                                        |
                     +----------------+                    +----------------+
                     |    Compute    |                    |    Budget     |
                     |   Optimizer   |                    |   Monitoring  |
                     +----------------+                    +----------------+
```

Key Component Interactions:
1. EventBridge Scheduler manages instance start/stop schedule
2. CloudWatch monitors instance metrics and triggers alarms
3. Auto Scaling Group adjusts capacity based on CloudWatch alarms
4. Compute Optimizer analyzes usage patterns and provides recommendations
5. Budget monitoring tracks costs and sends notifications
6. IAM roles and policies control access and permissions
7. Spot instance management optimizes instance costs

## Infrastructure

![Infrastructure diagram](./docs/infra.svg)

### Lambda Functions
- None defined

### IAM Resources
- Role: `ec2-optimizer-role` for EC2 instance management
- Policy: `ec2-cost-optimization-policy` for EC2 operations
- Instance Profile: `ec2-optimizer-profile`

### EventBridge Resources
- Schedule: `start-ec2-wednesdays` (Runs Wednesdays at 10 AM UTC)
- Schedule: `stop-ec2-on-fridays` (Runs Fridays at 5 PM UTC)

### CloudWatch Resources
- Alarm: `caid-ec2-cloudwatch-cpu-alarm` (CPU utilization > 80%)
- Alarm: `caid-ec2-cloudwatch-terminate-alarm` (CPU utilization < 5%)
- Alarm: `caid-ec2-cloudwatch-cost-alarm` (CPU utilization > 70%)

### EC2 Resources
- Launch Template with ARM-based Amazon Linux 2023 AMI
- Spot Instance with max price of $0.0031/hour
- Auto Scaling Group with capacity-based scaling

### AWS Budget
- Monthly budget of $200 USD for EC2 services
- Alert threshold at 80% of budget