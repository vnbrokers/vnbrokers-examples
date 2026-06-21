provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
    Schedule    = var.schedule_days
  }
}

resource "aws_subnet" "han_public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.han_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-subnet-han"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
    Zone        = "han-local"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rt-public"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

resource "aws_route_table_association" "han_public" {
  subnet_id      = aws_subnet.han_public.id
  route_table_id = aws_route_table.public.id
}
