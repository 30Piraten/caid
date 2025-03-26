variable "vpc_cidr" {
  type = string 
  description = "VPC CIDR block"
  default = "10.0.0.0/16"

  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be valid CIDR notation"
  }
}

variable "project_name" {
  type = string 
  default = "caid-vpc-wk1"
  description = "The project name for VPC"
}

variable "environment" {
  description = "Deployment environment"
  type = string
  default = "dev"
}

variable "availability_zones" {
  type = list(string) 
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  description = "List of Availability Zones to use"
}