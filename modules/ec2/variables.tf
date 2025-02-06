variable "instance_type" {
  description = "The EC2 instance type"
  default     = "t2.micro"
}

variable "public_subnet_id" {
  description = "The subnet ID for the public subnet"
  type        = string
}

/*
variable "private_subnet_id" {
  description = "The subnet ID for the private subnet"
  type        = string
}
*/
variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "env_name" {
  description = "Environment name (dev, prod, etc.)"
  default     = "dev"
}

variable "security_group_id" {
  description = "The security group ID to associate with the EC2 instances"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for the resources"
  type        = string
}

variable "user_data" {
  description = "User data to be passed to EC2 instances"
  type        = string
}
