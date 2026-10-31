
data "azurerm_kubernetes_cluster" "existing" {
  name                = "aks-crew-student"
  resource_group_name = "rg-crew-student-aks"
}

data "azurerm_subnet" "aks" {
  name                 = "subnet-aks"
  virtual_network_name = "vnet-crew-student"
  resource_group_name  = "rg-crew-student-aks"
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.existing.id

  mode                 = "User"
  vm_size              = "Standard_D2s_v4"
  node_count           = 1
  auto_scaling_enabled = false

  os_type         = "Linux"
  os_disk_type    = "Managed"
  os_disk_size_gb = 64

  max_pods       = 30
  vnet_subnet_id = data.azurerm_subnet.aks.id

  node_labels = {
    workload = "apps"
  }

  # Doit rester DANS la ressource
  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }
}

