resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
        Name = "${var.resource_prefix}vpc_${var.env_name}_us-east-1"
  }
}

# Public Subnet 1 (Now using a custom route table)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidr_1
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.resource_prefix}-public-subnet-1-${var.env_name}-us-east-1"
  }
}

# Public Subnet 2 (Now using a custom route table)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidr_2
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.resource_prefix}-public-subnet-2-${var.env_name}-us-east-1"  }
}

# Private Subnet 1 (Using a custom route table, but no Internet Gateway route)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_cidr_1
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.resource_prefix}-private-subnet-1-${var.env_name}-us-east-1"
  }
}

# Private Subnet 2 (Using a custom route table, but no Internet Gateway route)
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_cidr_2
  availability_zone = "us-east-1b"
  tags = {
    Name = "${var.resource_prefix}-private-subnet-2-${var.env_name}-us-east-1"
  }
}

# Internet Gateway (For Public Subnet Access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.resource_prefix}-vpc-${var.env_name}-igw"
  }
}

# Add a route to the custom public route table for public subnet internet access
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id            = aws_internet_gateway.igw.id

  depends_on = [aws_internet_gateway.igw]
}

# Data Source to fetch the default main route table ID
data "aws_route_table" "default_main_rt" {
  vpc_id = aws_vpc.vpc.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Tag the default main route table with the custom name format
resource "null_resource" "tag_main_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]

  provisioner "local-exec" {
    command = <<EOT
      aws ec2 create-tags --resources ${data.aws_route_table.default_main_rt.id} --tags Key=Name,Value=${var.resource_prefix}vpc_${var.env_name}_main_public_rt
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Create a custom route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.resource_prefix}-vpc-${var.env_name}-public-rt"
  }
}

# Associate the public subnets with the custom public route table
resource "aws_route_table_association" "public_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a custom route table for the private subnets (No Internet Gateway route)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.resource_prefix}-vpc-${var.env_name}-private-rt"
  }
}
