terraform {
    required_providers {
      aws ={
        source = "hashicorp/aws"
        version = "~>5.0"
      }

    random = {
        source = "hashicorp/random"
        version = "~>3.1"
    }
    tls = {
        source = "hashicorp/tls"
        version = "~>4.0"
    }
  }
}

provider "aws" {
    region = "ap-south-1"
}

# generate a random password for the RDS instance
resource "random_password" "db_pass" {
    length = 16
    special = true
}

# generate ssh key pair

resource "tls_private_key" "ssh_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

# Store the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/terraform-key.pem"
  file_permission = "0600"
}

# create a aws key pair 
resource "aws_key_pair" "main" {
    key_name = "${var.project_name}-key"
    public_key = tls_private_key.ssh_key.public_key_openssh     # using the public key from the tls_private_key resource
}

# data source to get available AZs
data "aws_avaiable_zones" "available" {
  state = "available"
}

# data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

}

# Create a vpc 
resource "aws_vpc" "main"{
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags ={
        name = "${var.project_name}-vpc"
        }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr
    availability_zone = data.aws_avaiable_zones.available.names[0]  # Use the first available AZ
    map_public_ip_on_launch = true
    tags = {
        name = "${var.project_name}-public-subnet"
    }
}

# create a private subnet
resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr
    availability_zone = data.aws_avaiable_zones.available.names[0]
    map_public_ip_on_launch = true
    tags = {
        name = "${var.project_name}-private-subnet-1"
    }
}

# create a private subnet for rds
resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = data.aws_avaiable_zones.available.names[1]  # Use the second available AZ
    map_public_ip_on_launch = true
    tags = {
        name = "${var.project_name}-private-subnet-2"
    }
}

# Route table for public subnet
resource "aws_route_table" "public" {
     vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
    }
}

# associate the public route table with the public subnet
resource 
