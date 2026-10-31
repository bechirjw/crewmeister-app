
output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.this.name
}

output "aks_name" {
  description = "AKS cluster name"
  value       = module.aks.name
}

output "aks_id" {
  description = "AKS cluster resource ID"
  value       = module.aks.id
}

output "aks_subnet_id" {
  description = "AKS subnet ID if custom network is enabled"
  value       = var.create_custom_network ? module.network[0].aks_subnet_id : null
}

output "vnet_id" {
  description = "Azure VNet ID if created"
  value       = var.create_custom_network ? module.network[0].vnet_id : null
}

output "budget_id" {
  description = "Azure budget ID if enabled"
  value       = module.budget.id
}

output "get_credentials_command" {
  description = "Command to configure kubectl access to AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.name} --context crewmeister-aks-student"
}
