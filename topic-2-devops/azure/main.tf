terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "public_ip" {
  name                         = var.public_ip_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  allocation_method = "Static"
  idle_timeout_in_minutes      = 4
  sku                          = "Basic"

  tags = {
    Name = "lab_public_ip"
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "ssh_key" {
  provisioner "local-exec" {
    command = <<-EOT
      rm -f ./'${var.ssh_key_name}'.pem 2> /dev/null
      echo '${tls_private_key.key.private_key_pem}' > ./'${var.ssh_key_name}'.pem
      chmod 400 ./'${var.ssh_key_name}'.pem
    EOT
  }
}

resource "azurerm_network_interface" "nic" {
  name                     = var.nic_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name

  tags = {
    Name = "lab_nic"
  }

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "topic-2-lab" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_username = var.vm_admin_username
  
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.key.public_key_openssh
  }

  user_data = base64encode(templatefile("cloud_init.yml.tftpl", {
    wg_port                      = var.wg_port,
    public_iface                 = var.public_iface,
    vpn_network_address          = var.vpn_network_address,
    docker_compose_b64_encoded   = filebase64("${path.root}/uploads/docker-compose.yml"),
    nginx_conf_b64_encoded       = filebase64("${path.root}/uploads/nginx.conf"),
    setup_nginx_conf_b64_encoded = filebase64("${path.root}/uploads/setup_nginx.conf"),
    init_script_b64_encoded      = filebase64("${path.root}/uploads/init_script.sh"),
    setting_up_page_b64_encoded  = filebase64("${path.root}/uploads/index.html"),
    subscription_id              = var.subscription_id, 
    aws_account_id               = var.aws_account_id,
    region                       = var.region
  }))
  
  computer_name = substr(var.vm_name, 0, 15)

  os_disk {
    name              = "${var.vm_name}_os_disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name = "lab_vm"
  }

  depends_on = [
    azurerm_network_security_group.nsg
  ]
}