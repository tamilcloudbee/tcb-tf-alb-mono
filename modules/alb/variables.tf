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


variable "env_name" {
  description = "Environment name"
  type        = string
}

/*
variable "main_instance_ids" {
  description = "Map of main EC2 instance IDs"
  type        = map(string)
}
*/

variable "security_groups" {
  description = "alb Security group"
  type        = string

}

variable "instance_id" {
  description = "The ID of the instance to attach to the ALB target group"
  type        = string
}
