terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables
variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy the CTF lab"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone to deploy the CTF lab"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_machine_type" {
  description = "The GCP machine type to deploy the CTF lab"
  type        = string
  default     = "e2-micro"
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

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
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

# Create a VPC network
resource "google_compute_network" "ctf_network" {
  name                    = "ctf-network"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "ctf_subnet" {
  name          = "ctf-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.ctf_network.id
}

# Create firewall rules for SSH and HTTP
resource "google_compute_firewall" "ctf_firewall_ssh" {
  name    = "ctf-allow-ssh"
  network = google_compute_network.ctf_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ctf-instance"]
}

resource "google_compute_firewall" "ctf_firewall_http" {
  name    = "ctf-allow-http"
  network = google_compute_network.ctf_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8083"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ctf-instance"]
}

# Create a compute instance
resource "google_compute_instance" "ctf_instance" {
  name         = "ctf-instance"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  tags = ["ctf-instance"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/family/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.ctf_network.id
    subnetwork = google_compute_subnetwork.ctf_subnet.id

    access_config {
      # This gives the instance a public IP
    }
  }

  # Metadata for the instance
  metadata = {
    enable-oslogin = "FALSE"
    startup-script = var.use_local_setup ? local.local_bootstrap_script : local.release_setup_script
  }

  # Service account for the instance
  service_account {
    email  = "default"
    scopes = ["cloud-platform"]
  }
}

# Wait for setup completion
resource "null_resource" "local_setup" {
  count      = var.use_local_setup ? 1 : 0
  depends_on = [google_compute_instance.ctf_instance]

  connection {
    type     = "ssh"
    host     = google_compute_instance.ctf_instance.network_interface[0].access_config[0].nat_ip
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
  depends_on = [google_compute_instance.ctf_instance]

  triggers = {
    instance_id = google_compute_instance.ctf_instance.id
  }

  connection {
    type     = "ssh"
    host     = google_compute_instance.ctf_instance.network_interface[0].access_config[0].nat_ip
    user     = "ctf_user"
    password = "CTFpassword123!"
    timeout  = "30m"
  }

  provisioner "remote-exec" {
    inline = [local.release_readiness_script]
  }
}

# Output the public IP address
output "public_ip_address" {
  value      = google_compute_instance.ctf_instance.network_interface[0].access_config[0].nat_ip
  depends_on = [null_resource.local_setup, null_resource.release_setup_ready]
}