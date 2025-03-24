/*
Right sizing enhancements:
- utilize AWS compute optimizer recommedations
  This refers to using AWS Compute Optimizer service which analyzes instance metrics 
  and provides recommendations for optimal instance types based on workload patterns
*/

# Enable AWS Compute Optimizer for EC2 instances
resource "aws_computeoptimizer_enrollment_status" "ec2_optimiser" {
  status = "Active"
}

# Configure recommendation preferences for EC2 instance optimization
resource "aws_computeoptimizer_recommendation_preferences" "ec2_preference" {
  resource_type = "Ec2Instance"
  
  # Define the scope to target a specific EC2 instance
  scope {
    name  = "ResourceArn"
    value = aws_instance.server.arn
  }

  # Enable enhanced metrics collection for better recommendations
  enhanced_infrastructure_metrics = "Active"
  
  # Configure external metrics integration with Datadog
  external_metrics_preference {
    source = "Datadog"
  }

  # Specify allowed instance types for recommendations
  preferred_resource {
    include_list = ["t4g.medium", "m6g.medium"]
    name         = "Ec2InstanceTypes"
  }
}
