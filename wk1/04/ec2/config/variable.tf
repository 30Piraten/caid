variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "permissions_boundary_arn" {
  type = string 
  default = "null"
}

# INSTANCE CONFIG
variable "instance_type" {
  type = string 
  default = "t4g.micro"
}

variable "name_prefix" {
  type = string 
  default = "launch-template"
}

variable "market_type" {
  type = string 
  default = "spot"
}

# AUTO SCALING GROUP
variable "ec2_capacity_based_policy_name" {
  type = string 
  default = "ec2-capacity-based-scaling-policy"
}

variable "ec2_scale_down_policy_name" {
  type = string 
  default = "ec2-terminate-idle-instance"
}

variable "ec2_cost_based_policy_name" {
  type = string 
  default = "ec2-cost-based-policy"
}

variable "scaling_down_schedule_name" {
  type = string
  default = "scale-down-night"
}

variable "scaling_up_morning_schedule_name" {
  type = string 
  default = "scale-up-morning"
}

# SCHEDULER CONFIG 
variable "start_instance_scheduler_name" {
  type = string 
  default = "start-ec2-wednesdays"
}

variable "stop_instance_scheduler_name" {
  type = string
  default = "stop-ec2-on-fridays"
}