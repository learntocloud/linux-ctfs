
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
# Configure the AWS Provider
# Define the region variable
variable "aws_region" {
  description = "The AWS region to deploy the CTF lab"
  type        = string
  default     = "us-east-1"  # Default region if not specified
}

variable "use_local_setup" {
  description = "Use local ctf_setup.sh instead of fetching from GitHub (for testing)"
  type        = bool
  default     = false
}

# Configure the AWS Provider with the variable region
provider "aws" {
  region = var.aws_region
}

# Compress the setup script to fit within AWS user_data limit (16KB limit for base64)
data "external" "compressed_setup" {
  count   = var.use_local_setup ? 1 : 0
  program = ["bash", "-c", "jq -n --arg data \"$(gzip -c ${path.module}/../ctf_setup.sh | base64)\" '{compressed: $data}'"]
}

# Fetch availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC
resource "aws_vpc" "ctf_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "CTF Lab VPC"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "ctf_igw" {
  vpc_id = aws_vpc.ctf_vpc.id

  tags = {
    Name = "CTF Lab IGW"
  }
}

# Create a Subnet
resource "aws_subnet" "ctf_subnet" {
  vpc_id     = aws_vpc.ctf_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "CTF Lab Subnet"
  }
}

# Create a Route Table
resource "aws_route_table" "ctf_route_table" {
  vpc_id = aws_vpc.ctf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ctf_igw.id
  }

  tags = {
    Name = "CTF Lab Route Table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "ctf_route_table_assoc" {
  subnet_id      = aws_subnet.ctf_subnet.id
  route_table_id = aws_route_table.ctf_route_table.id
}

# Create a Security Group
resource "aws_security_group" "ctf_sg" {
  name        = "ctf_sg"
  description = "Security group for CTF lab"
  vpc_id      = aws_vpc.ctf_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CTF Lab Security Group"
  }
}


# Create an EC2 Instance
data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ctf_instance" {
  ami           = data.aws_ami.ubuntu.id 
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ctf_sg.id]
  subnet_id              = aws_subnet.ctf_subnet.id

  associate_public_ip_address = true

  # Use local file for testing, GitHub for production
  # AWS supports gzip-compressed user_data (cloud-init auto-decompresses)
  user_data_base64 = var.use_local_setup ? data.external.compressed_setup[0].result.compressed : base64encode(<<-EOF
    #!/bin/bash
    curl -fsSL https://raw.githubusercontent.com/learntocloud/linux-ctfs/main/ctf_setup.sh | bash
  EOF
  )

  tags = {
    Name = "CTF Lab Instance"
  }
}

resource "null_resource" "wait_for_setup" {
  depends_on = [aws_instance.ctf_instance]
  
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = aws_instance.ctf_instance.public_ip
      user     = "ctf_user"
      password = "CTFpassword123!"
      timeout  = "10m"
    }
    
    inline = [
      "while [ ! -f /var/log/setup_complete ]; do sleep 10; done"
    ]
  }
}

# Output the public IP of the instance
output "public_ip_address" {
  value = aws_instance.ctf_instance.public_ip
}
# Desired state of the EC2 instance
variable "ctf_instance_state" {
  description = "Desired state of the EC2 instance (running or stopped)"
  type        = string
  default     = "running"
}

# Control EC2 instance state declaratively
resource "aws_ec2_instance_state" "ctf_instance_state" {
  instance_id = aws_instance.ctf_instance.id
  state       = var.ctf_instance_state
}
