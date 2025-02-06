variable "resource_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "load_balancer_type" {
  description = "The type of load balancer (e.g., application or network)"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "main_instance_ids" {
  description = "Map of main EC2 instance IDs"
  type        = map(string)
}

variable "admin_instance_ids" {
  description = "Map of admin EC2 instance IDs"
  type        = map(string)
}

variable "register_instance_ids" {
  description = "Map of register EC2 instance IDs"
  type        = map(string)
}
