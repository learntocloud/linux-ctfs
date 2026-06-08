# main.tf
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.55.0" # Minimum version that supports azurerm_virtual_machine_power action
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
# Variables
variable "az_region" {
  description = "The region to deploy the CTF lab"
  type        = string
  default     = "East US"
}

variable "azure_vm_size" {
  description = "The Azure VM size to deploy the CTF lab"
  type        = string
  default     = "Standard_B1s"
}

variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
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
      echo "CTF setup failed. Check /var/log/ctf_setup.log and Azure Custom Script Extension logs." >&2
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

    wait_for_cloud_init() {
      if command -v cloud-init >/dev/null 2>&1; then
        cloud-init status --wait || true
      fi
    }

    apt_get_update_with_retry() {
      local attempt
      for attempt in 1 2 3 4 5; do
        if apt-get -o DPkg::Lock::Timeout=120 -o Acquire::Retries=3 update; then
          return 0
        fi
        echo "apt-get update failed. Attempt $${attempt}/5."
        rm -rf /var/lib/apt/lists/partial/*
        sleep 10
      done
      return 1
    }

    wait_for_cloud_init
    apt_get_update_with_retry
    apt-get -o DPkg::Lock::Timeout=120 -o Acquire::Retries=3 install -y ca-certificates curl tar gzip coreutils

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

  azure_release_extension_script = <<-EOF
#!/bin/sh
exec /bin/bash <<'LINUX_CTFS_SETUP'
${local.release_setup_script}
LINUX_CTFS_SETUP
  EOF
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Create a resource group
resource "azurerm_resource_group" "ctf_rg" {
  name     = "ctf-resources"
  location = var.az_region
}

# Create a virtual network
resource "azurerm_virtual_network" "ctf_network" {
  name                = "ctf-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name
}

# Create a subnet
resource "azurerm_subnet" "ctf_subnet" {
  name                 = "ctf-subnet"
  resource_group_name  = azurerm_resource_group.ctf_rg.name
  virtual_network_name = azurerm_virtual_network.ctf_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "ctf_public_ip" {
  name                = "ctf-public-ip"
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create a network security group
resource "azurerm_network_security_group" "ctf_nsg" {
  name                = "ctf-nsg"
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "CTF-Service"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "CTF-Nginx"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8083"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create a network interface
resource "azurerm_network_interface" "ctf_nic" {
  name                = "ctf-nic"
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ctf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ctf_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "ctf_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.ctf_nic.id
  network_security_group_id = azurerm_network_security_group.ctf_nsg.id
}

# Create a Linux virtual machine for CTF
resource "azurerm_linux_virtual_machine" "ctf_vm" {
  name                = "ctf-vm"
  resource_group_name = azurerm_resource_group.ctf_rg.name
  location            = azurerm_resource_group.ctf_rg.location
  size                = var.azure_vm_size
  admin_username      = "ctf_user"
  network_interface_ids = [
    azurerm_network_interface.ctf_nic.id,
  ]

  admin_password                  = "CTFpassword123!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = var.use_local_setup ? base64encode(local.local_bootstrap_script) : null
}

resource "azurerm_virtual_machine_extension" "release_setup" {
  count                = var.use_local_setup ? 0 : 1
  name                 = "linux-ctfs-release-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.ctf_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = jsonencode({
    script = base64encode(local.azure_release_extension_script)
  })

  tags = {
    setup_release_tag = var.setup_release_tag
  }
}

action "azurerm_virtual_machine_power" "ctf_power_off" {
  config {
    virtual_machine_id = azurerm_linux_virtual_machine.ctf_vm.id
    power_action       = "power_off"
  }
}

action "azurerm_virtual_machine_power" "ctf_power_on" {
  config {
    virtual_machine_id = azurerm_linux_virtual_machine.ctf_vm.id
    power_action       = "power_on"
  }
}

resource "null_resource" "local_setup" {
  count      = var.use_local_setup ? 1 : 0
  depends_on = [azurerm_linux_virtual_machine.ctf_vm]

  connection {
    host     = azurerm_linux_virtual_machine.ctf_vm.public_ip_address
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

# Output the public IP address
output "public_ip_address" {
  value      = azurerm_linux_virtual_machine.ctf_vm.public_ip_address
  depends_on = [null_resource.local_setup, azurerm_virtual_machine_extension.release_setup]
}
