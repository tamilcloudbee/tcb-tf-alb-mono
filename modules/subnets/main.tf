
resource "aws_subnet" "this" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr
  #availability_zone = "us-east-1a"
  tags              = var.tags
}

# Public Route Table (Not used for association, but still created for clarity)
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id
  tags = {
    Name = "public-route-table-${var.env_name}-us-east-1"
  }
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id
  tags = {
    Name = "private-route-table-${var.env_name}-us-east-1"
  }
}

# Associate Public Subnet with Main Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.this.id
  route_table_id = data.aws_route_table.main.id
  depends_on = [data.aws_route_table.main]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.private_route_table.id
  depends_on = [aws_route_table.private_route_table]
}

# Create route to Internet Gateway for Public Route Table (if required)
resource "aws_route" "public_route_to_igw" {
  route_table_id         = data.aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id  # Make sure to pass the Internet Gateway ID for public subnets
}

# Data source to fetch the main route table for the VPC
data "aws_route_table" "main" {
  vpc_id = var.vpc_id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}
