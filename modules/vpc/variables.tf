variable "vpc_cidr" {}

variable "public_cidr_1" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "public_cidr_2" {
  description = "CIDR block for the second public subnet"
  type        = string
}

variable "private_cidr_1" {
  description = "CIDR block for the first private subnet"
  type        = string
}

variable "private_cidr_2" {
  description = "CIDR block for the second private subnet"
  type        = string
}

variable "env_name" {}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "demo_nlb_"
}
