provider "aws" {
  region = "us-east-1"
}

module "vpc_a" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_cidr_1   = var.public_cidr_1
  public_cidr_2   = var.public_cidr_2
  private_cidr_1  = var.private_cidr_1
  private_cidr_2  = var.private_cidr_2
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
  user_data           = file("user-data-admin.sh")
  key_name            = var.key_name
  env_name            = "dev_a"
  security_group_id   = module.sg_a.security_group_id
  resource_prefix     = var.resource_prefix
}

module "ec2_b" {
  source              = "./modules/ec2"
  instance_type       = "t2.micro"
  public_subnet_id    = module.vpc_a.public_subnet_2_id
  user_data           = file("user-data-register.sh")
  key_name            = var.key_name
  env_name            = "dev_a"
  security_group_id   = module.sg_a.security_group_id
  resource_prefix     = var.resource_prefix
}

module "alb" {
  source               = "./modules/alb"
  resource_prefix      = var.resource_prefix
  load_balancer_type   = "application"
  vpc_id               = module.vpc_a.vpc_id
  public_subnet_ids    = [module.vpc_a.public_subnet_1_id, module.vpc_a.public_subnet_2_id]
  security_group_ids   = [module.sg_a.alb_security_group_id]
  env_name             = "dev"
  main_instance_ids    = {
    "main_instance_1" = module.ec2_a.public_instance_id
    "main_instance_2" = module.ec2_b.public_instance_id
  }
  admin_instance_ids   = {
    "admin_instance_1" = module.ec2_a.public_instance_id
  }
  register_instance_ids = {
    "register_instance_1" = module.ec2_b.public_instance_id
  }
}