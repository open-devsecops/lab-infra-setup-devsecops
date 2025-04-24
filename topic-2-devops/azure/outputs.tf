output "please_note" {
  value = [
    "Tool installation could take several minutes to complete.",
    "Verify completion by entering the following command on the server:",
    "grep 'Lab Infrastructure Provisioning Complete' /var/log/cloud-init-output.log"
  ]
}

output "SSH" {
  value = "ssh -i ${var.ssh_key_name}.pem ${var.vm_admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}

output "vm_public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "The public IP address of the virtual machine."
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_student_token_username" {
  value = azurerm_container_registry_token.student.name
}

output "acr_student_token_password" {
  value     = azurerm_container_registry_token_password.student_pwd.password1
  sensitive = true
}