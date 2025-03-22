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
variable "" {
  
}