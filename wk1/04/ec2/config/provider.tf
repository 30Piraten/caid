terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.90.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  profile = "tf-user"
}