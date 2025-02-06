

# Data block to fetch the latest Ubuntu AMI ID in the region


data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Ubuntu official owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]  # Updated to include all Ubuntu images
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]  # Use x86_64 architecture (compatible with t2.micro)
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



# EC2 Instance in the Public Subnet
resource "aws_instance" "public_instance" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name
  associate_public_ip_address = true
  security_groups = [var.security_group_id]
  user_data              = var.user_data  # Pass the user data here
  tags = {
    Name        = "${var.resource_prefix}-Public-Instance-${var.public_subnet_id}"
    Environment = var.env_name
  }
}
