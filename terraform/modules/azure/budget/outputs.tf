output "id" {
  value = try(azurerm_consumption_budget_subscription.this[0].id, null)
}

output "name" {
  value = try(azurerm_consumption_budget_subscription.this[0].name, null)
}
