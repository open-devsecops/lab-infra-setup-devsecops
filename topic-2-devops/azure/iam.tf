resource "azurerm_role_definition" "custom_role" {
  name        = "example-role"
  scope       = "/subscriptions/e2270428-9eaa-4af7-b909-d190829450ae"  # Directly use your subscription ID here
  description = "An example custom role definition."

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
  }

  assignable_scopes = [
    "/subscriptions/e2270428-9eaa-4af7-b909-d190829450ae"  # Again, using the subscription ID here
  ]
}

resource "azurerm_role_assignment" "assign_role" {
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
  role_definition_name = azurerm_role_definition.custom_role.name
  scope           = azurerm_resource_group.rg.id

  depends_on = [azurerm_linux_virtual_machine.vm]
}