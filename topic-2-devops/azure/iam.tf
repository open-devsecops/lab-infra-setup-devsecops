data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "vm_identity" {
  name                = "VMIdentity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_user_assigned_identity" "student_identity" {
  name                = "StudentIdentity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_definition" "vm_role" {
  name        = "VMRole3"
  scope       = azurerm_resource_group.rg.id
  description = "Equivalent to AWS EC2 IAM Role"

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.rg.id
  ]
}

resource "azurerm_role_definition" "student_role" {
  name        = "StudentRole3"
  scope       = azurerm_resource_group.rg.id
  description = "Equivalent to AWS Student IAM Role"

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
  }

  assignable_scopes = [
    azurerm_resource_group.rg.id
  ]
}

resource "azurerm_role_assignment" "vm_role_assignment" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.vm_role.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.vm_identity.principal_id
}

resource "azurerm_role_assignment" "student_role_assignment" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.student_role.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.student_identity.principal_id
}

resource "azurerm_role_assignment" "vm_assume_student_role" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.student_role.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.vm_identity.principal_id
}