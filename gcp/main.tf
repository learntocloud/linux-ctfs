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

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
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
  machine_type = "e2-micro"  
  zone         = var.gcp_zone

  tags = ["ctf-instance"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
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
    startup-script = file("${path.module}/ctf_setup.sh")
  }

  # Service account for the instance
  service_account {
    email  = "default"
    scopes = ["cloud-platform"]
  }
}

# Wait for setup completion
resource "null_resource" "wait_for_setup" {
  depends_on = [google_compute_instance.ctf_instance]
  
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = google_compute_instance.ctf_instance.network_interface[0].access_config[0].nat_ip
      user     = "ctf_user"
      password = "CTFpassword123!"
    }
    
    inline = [
      "while [ ! -f /var/log/setup_complete ]; do sleep 10; done"
    ]
  }
}

# Output the public IP address
output "ctf_instance_public_ip" {
  value = google_compute_instance.ctf_instance.network_interface[0].access_config[0].nat_ip
  depends_on = [null_resource.wait_for_setup]
}