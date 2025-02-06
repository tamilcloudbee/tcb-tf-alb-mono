variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}

variable "env_name" {}


variable "resource_prefix" {
  description = "Prefix for the resources"
  type        = string
}
