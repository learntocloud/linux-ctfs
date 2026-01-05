# main.tf

# Variables
variable "az_region" {
  description = "The region to deploy the CTF lab"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type = string
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
  sku                = "Standard"
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
  size                = "Standard_B1s"
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
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    curl -fsSL https://raw.githubusercontent.com/learntocloud/linux-ctfs/feature/ctf-v2-improvements/ctf_setup.sh | bash
  EOF
  )
}

resource "null_resource" "wait_for_setup" {
  depends_on = [azurerm_linux_virtual_machine.ctf_vm]
  
  provisioner "remote-exec" {
    connection {
      host     = azurerm_linux_virtual_machine.ctf_vm.public_ip_address
      user     = "ctf_user"
      password = "CTFpassword123!"
    }
    
    inline = [
      "while [ ! -f /var/log/setup_complete ]; do sleep 10; done"
    ]
  }
}

# Output the public IP address
output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ctf_vm.public_ip_address
  depends_on = [null_resource.wait_for_setup]
}