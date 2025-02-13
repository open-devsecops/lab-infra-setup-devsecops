variable "resource_group_name" {
  description = "The name of the resource group."
  default     = "lab_rg"
}

variable "location" {
  description = "The Azure region to deploy the resources."
  default     = "West US"
}

variable "vnet_name" {
  description = "The name of the virtual network."
  default     = "lab_vnet"
}

variable "vnet_address_space" {
  description = "The address space of the virtual network."
  default     = "10.0.0.0/16" //cidr_block
}

variable "subnet_name" {
  description = "The name of the subnet."
  default     = "lab_subnet"
}

variable "subnet_address_prefix" {
  description = "The address prefix for the subnet."
  default     = "10.0.1.0/24" //cidr_block
}

variable "public_ip_name" {
  description = "The name of the public IP."
  default     = "lab_public_ip"
}

variable "nic_name" {
  description = "The name of the NIC."
  default     = "lab_nic"
}

variable "vm_name" {
  description = "The name of the virtual machine."
  default     = "labvm"
}

variable "vm_size" {
  description = "The size of the virtual machine."
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "The administrator username for the VM."
  default     = "azureuser"
}

variable "ssh_key_name" {
  description = "The SSH key name for the VM."
  default     = "lab_key"
}

variable "wg_port" {
  description = "The port for the Wireguard VPN."
  default     = "21210"
}

variable "public_iface" { 
  type = string
  default = "ens5" 
}

variable "vpn_network_address" {
  type = string
  default = "192.168.77.1/24"
}

variable "region" {
 type        = string
 default     = "us-west-1"
}

variable "nsg_name" {
  description = "The name of the network security group."
  default     = "lab_nsg"
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default     = "e2270428-9eaa-4af7-b909-d190829450ae"
}