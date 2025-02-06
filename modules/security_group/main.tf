

resource "aws_security_group" "ec2_sg" {
  name        = "${var.resource_prefix}-ec2-sg"
  description = "Allow inbound traffic from ALB to EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Allow traffic from ALB's SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource_prefix}-ec2-sg"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "${var.resource_prefix}-alb-sg"
  description = "Allow traffic from ALB to EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all incoming HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource_prefix}-alb-sg"
  }
}
