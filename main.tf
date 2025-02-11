provider "aws" {
  region = "us-east-1"
}

module "vpc_a" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_cidr_1   = var.public_cidr_1
  public_cidr_2   = var.public_cidr_2

  private_cidr_1  = var.private_cidr_1
  env_name        = "dev_a"
  resource_prefix = var.resource_prefix

}

module "sg_a" {
  source   = "./modules/security_group"
  vpc_id   = module.vpc_a.vpc_id
  env_name = "dev_a"
  resource_prefix = var.resource_prefix
}

module "ec2_a" {
  source              = "./modules/ec2"
  instance_type       = "t2.micro"
  public_subnet_id    = module.vpc_a.public_subnet_1_id
  user_data           = templatefile("userdata-apache-fastapi-mysql-fullstack.sh", { alb_dns_name = module.alb.alb_dnsname })
  key_name            = var.key_name
  env_name            = "dev_a"
  security_group_id   = module.sg_a.security_group_id
  resource_prefix     = var.resource_prefix
}

module "alb" {
  source             = "./modules/alb"  # Path to the ALB module
  resource_prefix    = var.resource_prefix
  load_balancer_type = "application"
  security_groups    = module.sg_a.alb_security_group_id
  env_name           = "dev_a"
  vpc_id            = module.vpc_a.vpc_id  # Replace with your actual VPC ID
  public_subnet_ids  = [module.vpc_a.public_subnet_1_id, module.vpc_a.public_subnet_2_id]  # Replace with your public subnets
  instance_id    = module.ec2_a.public_instance_id   # Replace with actual EC2 instance IDs

}


