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

# ──────────────────────────────────────────────────────────────────────────────
# Resource Group & Networking
# ──────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  allocation_method        = "Static"
  idle_timeout_in_minutes  = 4
  sku                      = "Basic"

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
  name                = var.nic_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

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

# ──────────────────────────────────────────────────────────────────────────────
# Virtual Machine with System-Assigned Identity
# ──────────────────────────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine" "topic-2-lab" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  network_interface_ids = [ azurerm_network_interface.nic.id ]
  admin_username        = var.vm_admin_username

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.key.public_key_openssh
  }

  user_data = base64encode(
    templatefile("cloud_init.yml.tftpl", {
      wg_port                      = var.wg_port,
      public_iface                 = var.public_iface,
      vpn_network_address          = var.vpn_network_address,
      docker_compose_b64_encoded   = filebase64("${path.root}/uploads/docker-compose.yml"),
      nginx_conf_b64_encoded       = filebase64("${path.root}/uploads/nginx.conf"),
      setup_nginx_conf_b64_encoded = filebase64("${path.root}/uploads/setup_nginx.conf"),
      init_script_b64_encoded      = filebase64("${path.root}/uploads/init_script.sh"),
      setting_up_page_b64_encoded  = filebase64("${path.root}/uploads/index.html"),
      subscription_id              = var.subscription_id,
      acr_name                     = var.acr_name,
      region                       = var.region
    })
  )

  computer_name = substr(var.vm_name, 0, 15)

  os_disk {
    name                 = "${var.vm_name}_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
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
# ──────────────────────────────────────────────────────────────────────────────
# Azure Container Registry & Scope Map & Token
# ──────────────────────────────────────────────────────────────────────────────

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku           = "Premium"  # Required for scope maps & tokens
  admin_enabled = false
}

data "azurerm_role_definition" "acr_contributor" {
  name  = "Contributor"
  scope = azurerm_container_registry.acr.id
}

resource "azurerm_role_assignment" "vm_acr_contributor" {
  scope              = azurerm_container_registry.acr.id
  role_definition_id = data.azurerm_role_definition.acr_contributor.id
  principal_id       = azurerm_linux_virtual_machine.topic-2-lab.identity[0].principal_id
}

resource "azurerm_container_registry_scope_map" "student" {
  name                    = "StudentScopeMap"
  resource_group_name     = azurerm_resource_group.rg.name
  container_registry_name = azurerm_container_registry.acr.name
  description             = "Allow students to push/pull and read metadata"

  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read",
  ]
}

resource "azurerm_container_registry_token" "student" {
  name                    = "StudentToken"
  resource_group_name     = azurerm_resource_group.rg.name
  container_registry_name = azurerm_container_registry.acr.name
  scope_map_id            = azurerm_container_registry_scope_map.student.id
}

# ──────────────────────────────────────────────────────────────────────────────
# Generate the first password for that Token
# ──────────────────────────────────────────────────────────────────────────────

resource "azurerm_container_registry_token_password" "student_pwd" {
  container_registry_token_id = azurerm_container_registry_token.student.id

  password1 {
    expiry = "2025-12-31T23:59:59Z"
  }
}