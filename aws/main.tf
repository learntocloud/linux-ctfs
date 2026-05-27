
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
# Configure the AWS Provider
# Define the region variable
variable "aws_region" {
  description = "The AWS region to deploy the CTF lab"
  type        = string
  default     = "us-east-1" # Default region if not specified
}

variable "use_local_setup" {
  description = "Upload and run the local setup package instead of using a pinned release asset (for contributor testing)"
  type        = bool
  default     = false
}

variable "setup_release_tag" {
  description = "GitHub release tag that contains the setup package assets, or latest for the newest release"
  type        = string
  default     = "latest"
}

# Configure the AWS Provider with the variable region
provider "aws" {
  region = var.aws_region
}

locals {
  setup_asset_name   = "linux-ctfs-setup.tar.gz"
  setup_release_base = var.setup_release_tag == "latest" ? "https://github.com/learntocloud/linux-ctfs/releases/latest/download" : "https://github.com/learntocloud/linux-ctfs/releases/download/${var.setup_release_tag}"
  setup_release_url  = "${local.setup_release_base}/${local.setup_asset_name}"
  setup_checksum_url = "${local.setup_release_url}.sha256"

  local_bootstrap_script = <<-EOF
    #!/bin/bash
    set -e
    useradd -m -s /bin/bash ctf_user 2>/dev/null || true
    echo 'ctf_user:CTFpassword123!' | chpasswd
    usermod -aG sudo ctf_user
    echo 'ctf_user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ctf-user
    chmod 440 /etc/sudoers.d/90-ctf-user
    mkdir -p /etc/ssh/sshd_config.d
    printf 'PasswordAuthentication yes\nKbdInteractiveAuthentication yes\n' > /etc/ssh/sshd_config.d/99-ctf-local-bootstrap.conf
    systemctl restart ssh || systemctl restart sshd || true
  EOF

  release_setup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    STATE_DIR="/var/lib/linux-ctfs"
    FAILED_MARKER="$${STATE_DIR}/setup.failed"
    DONE_MARKER="$${STATE_DIR}/setup.done"
    INSTALL_DIR="/opt/linux-ctfs-setup"
    WORK_DIR="/opt/linux-ctfs-download"
    ASSET_NAME="${local.setup_asset_name}"
    SETUP_URL="${local.setup_release_url}"
    CHECKSUM_URL="${local.setup_checksum_url}"

    mkdir -p "$${STATE_DIR}" "$${WORK_DIR}"
    rm -f "$${FAILED_MARKER}"

    fail_setup() {
      echo "CTF setup failed. Check /var/log/cloud-init-output.log and /var/log/ctf_setup.log." >&2
      touch "$${FAILED_MARKER}"
    }
    trap fail_setup ERR

    download_with_retry() {
      local url="$1"
      local output="$2"
      local attempt
      for attempt in 1 2 3 4 5; do
        if curl -fL --retry 3 --retry-delay 5 --connect-timeout 20 "$${url}" -o "$${output}"; then
          return 0
        fi
        echo "Download failed for $${url}. Attempt $${attempt}/5."
        sleep 10
      done
      return 1
    }

    apt-get update
    apt-get install -y ca-certificates curl tar gzip coreutils

    cd "$${WORK_DIR}"
    download_with_retry "$${SETUP_URL}" "$${ASSET_NAME}"
    download_with_retry "$${CHECKSUM_URL}" "$${ASSET_NAME}.sha256"
    sha256sum -c "$${ASSET_NAME}.sha256"

    rm -rf "$${INSTALL_DIR}"
    mkdir -p "$${INSTALL_DIR}"
    tar -xzf "$${ASSET_NAME}" -C "$${INSTALL_DIR}"
    chmod +x "$${INSTALL_DIR}/ctf_setup.sh"
    "$${INSTALL_DIR}/ctf_setup.sh"

    touch "$${DONE_MARKER}"
    rm -f "$${FAILED_MARKER}"
    trap - ERR
  EOF

  release_readiness_script = <<-EOF
    set -eu
    echo "Waiting for CTF setup to finish..."
    for attempt in $(seq 1 180); do
      if test -f /var/lib/linux-ctfs/setup.failed; then
        echo "CTF setup failed. Check /var/log/ctf_setup.log and /var/log/cloud-init-output.log." >&2
        exit 1
      fi

      if test -f /var/lib/linux-ctfs/setup.done || test -f /var/lib/cloud/instance/ctf-setup.done || test -f /var/log/setup_complete; then
        echo "CTF setup is complete."
        exit 0
      fi

      echo "CTF setup is still running. Attempt $attempt/180."
      sleep 10
    done

    echo "Timed out waiting for CTF setup. Check /var/log/ctf_setup.log and /var/log/cloud-init-output.log." >&2
    exit 1
  EOF
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
  vpc_id            = aws_vpc.ctf_vpc.id
  cidr_block        = "10.0.1.0/24"
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

  user_data                   = var.use_local_setup ? local.local_bootstrap_script : local.release_setup_script
  user_data_replace_on_change = true

  tags = {
    Name = "CTF Lab Instance"
  }
}

resource "null_resource" "local_setup" {
  count      = var.use_local_setup ? 1 : 0
  depends_on = [aws_instance.ctf_instance]

  connection {
    type     = "ssh"
    host     = aws_instance.ctf_instance.public_ip
    user     = "ctf_user"
    password = "CTFpassword123!"
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/linux-ctfs-local-setup",
      "mkdir -p /tmp/linux-ctfs-local-setup"
    ]
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/.terraform && tar --exclude='__pycache__' --exclude='*.pyc' --exclude='.venv' -czf ${path.module}/.terraform/linux-ctfs-local-setup.tar.gz -C ${path.module}/.. ctf_setup.sh setup verify"
  }

  provisioner "file" {
    source      = "${path.module}/.terraform/linux-ctfs-local-setup.tar.gz"
    destination = "/tmp/linux-ctfs-local-setup.tar.gz"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "tar -xzf /tmp/linux-ctfs-local-setup.tar.gz -C /tmp/linux-ctfs-local-setup",
      "sudo chmod +x /tmp/linux-ctfs-local-setup/ctf_setup.sh && sudo /tmp/linux-ctfs-local-setup/ctf_setup.sh"
    ]
  }
}

resource "null_resource" "release_setup_ready" {
  count      = var.use_local_setup ? 0 : 1
  depends_on = [aws_instance.ctf_instance]

  triggers = {
    instance_id = aws_instance.ctf_instance.id
  }

  connection {
    type     = "ssh"
    host     = aws_instance.ctf_instance.public_ip
    user     = "ctf_user"
    password = "CTFpassword123!"
    timeout  = "30m"
  }

  provisioner "remote-exec" {
    inline = [local.release_readiness_script]
  }
}

# Output the public IP of the instance
output "public_ip_address" {
  value      = aws_instance.ctf_instance.public_ip
  depends_on = [null_resource.local_setup, null_resource.release_setup_ready]
}
# Desired state of the EC2 instance
variable "ctf_instance_state" {
  description = "Desired state of the EC2 instance (running or stopped)"
  type        = string
  default     = "running"

  validation {
    condition     = contains(["running", "stopped"], var.ctf_instance_state)
    error_message = "ctf_instance_state must be either \"running\" or \"stopped\"."
  }
}

# Control EC2 instance state declaratively
resource "aws_ec2_instance_state" "ctf_instance_state" {
  instance_id = aws_instance.ctf_instance.id
  state       = var.ctf_instance_state

  depends_on = [null_resource.local_setup, null_resource.release_setup_ready]
}
