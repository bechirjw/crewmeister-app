locals {
  prefix = "crew-${var.environment}"
}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}-aks"
  location = var.location
  tags     = var.tags
}

# Network
module "network" {
  count  = var.create_custom_network ? 1 : 0
  source = "../../../modules/azure/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  vnet_name         = "vnet-${local.prefix}"
  address_space     = ["10.50.0.0/16"]
  aks_subnet_prefix = "10.50.0.0/22"

  create_appgw_subnet = false

  tags = var.tags
}

# Identity for custom network
resource "azurerm_user_assigned_identity" "aks_control_plane" {
  count = var.create_custom_network ? 1 : 0

  name                = "id-aks-${local.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Network Contributor permissions
resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  count = var.create_custom_network ? 1 : 0

  scope = module.network[0].aks_subnet_id

  role_definition_name = "Network Contributor"

  principal_id = azurerm_user_assigned_identity.aks_control_plane[0].principal_id

  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# AKS Cluster
module "aks" {
  source = "../../../modules/azure/aks"

  cluster_name        = "aks-${local.prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  dns_prefix          = "aks-${local.prefix}"

  aks_subnet_id = (
    var.create_custom_network
    ? module.network[0].aks_subnet_id
    : null
  )

  identity_ids = (
    var.create_custom_network
    ? [azurerm_user_assigned_identity.aks_control_plane[0].id]
    : []
  )

  system_vm_size    = var.system_vm_size
  system_node_count = var.system_node_count

  service_cidr   = "10.3.0.0/16"
  dns_service_ip = "10.3.0.10"
  pod_cidr       = "10.244.0.0/16"

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_subnet_network_contributor
  ]
}

# Optional Budget
module "budget" {
  source = "../../../modules/azure/budget"

  enabled           = var.enable_budget
  name              = "budget-${local.prefix}"
  amount            = var.budget_amount
  time_period_start = var.budget_start

  notifications = var.enable_budget ? [
    {
      enabled        = true
      threshold      = 80
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_emails = var.budget_contact_emails
      contact_roles  = ["Owner"]
    }
  ] : []
}
