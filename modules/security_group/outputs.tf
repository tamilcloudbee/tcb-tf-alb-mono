

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}


output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}

