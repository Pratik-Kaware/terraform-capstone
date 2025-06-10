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
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

# Security group for ec2 
resource "aws_security_group" "ec2" {
    name_prefix "${var.project_name}-ec2-"
    vpc_id = aws_vpc.main.vpc_id

    # SSH aaccess 
    ingress = {
        from_port = 22
        to_port = 22  
        protocol = "tcp"
        cidr_block = var.allowed_cidr_blocks
    }
    
    # All outbound traffic
    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"  # -1 means all protocols
        cidr_block = ["0.0.0.0/0"]
    }
    tags = {
      Name = "${var.project_name}-ec2-sg"
    }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = aws_vpc.main.id

  # MySQL access from EC2
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# EC2 Instance

resource "aws_instance" "web" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = t2.micro            # Free tier eligible
    key_name = aws_key_pair.main.key_name           # using the key pair created earlier
    vpc_security_group_ids = [aws_security_group.ec2.id]  # Attach the security group
    subnet_id = aws_subnet.public.id
    user_data = file(userdata.sh)  # Assuming you have a user_data.sh file for initialization
    tags = {
        name = "${var.project_name}-web-server"
    }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
    identifier = "${var.project_name}-database"
    # free teir eligible instance type
    engine = "mysql"
    engine_version = "8.0.28"
    instance_class = "db.t3.micro"
    allocated_storage = 20

    # Database Configuration
    db_name = "mydatabase"
    username = "var.db_username"
    password = random_password.db_pass.result

    # network configuration
    db_subnet_group_name = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.rds.id]

    # Backup and maintenance
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Free tier optimizations
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-database"
  }
}

# Store database password in AWS Systems Manager Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/database/password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name = "${var.project_name}-db-password"
  }
}
