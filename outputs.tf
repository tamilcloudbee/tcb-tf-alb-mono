output "vpc_a_id" {
  value = module.vpc_a.vpc_id
}

output "public_subnet_id_1" {
  value = module.vpc_a.public_subnet_1_id
}

output "private_subnet_id_1" {
  value = module.vpc_a.private_subnet_1_id
}

/*

output "monolith_public_instance_id" {
  description = "The ID of the public EC2 instance"
  value       = module.ec2_a.output.public_instance.id
}

output "monolith_security_group_id" {
  description = "The ID of the public EC2 instance"
  value       = module.sg_a.output.security_group_id
}


*/
