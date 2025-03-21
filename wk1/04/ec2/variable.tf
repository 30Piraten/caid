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