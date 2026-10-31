
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version = var.kubernetes_version
  sku_tier           = "Free"

  private_cluster_enabled           = false
  role_based_access_control_enabled = true
  local_account_disabled            = false

  oidc_issuer_enabled       = false
  workload_identity_enabled = false
  azure_policy_enabled      = false

  # Pool systeme AKS : 1 noeud Standard_D4s_v3
  default_node_pool {
    name       = "system"
    vm_size    = var.system_vm_size
    node_count = var.system_node_count

    vnet_subnet_id       = var.aks_subnet_id
    auto_scaling_enabled = false

    os_disk_type    = "Managed"
    os_disk_size_gb = var.os_disk_size_gb

    max_pods = 30

    only_critical_addons_enabled = false

    node_labels = {
      workload = "mixed"
    }

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  # Identite du cluster AKS
  identity {
    type = length(var.identity_ids) > 0 ? "UserAssigned" : "SystemAssigned"

    identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
  }

  # Reseau Kubernetes : Azure CNI Overlay + Cilium
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"

    network_data_plane = "cilium"
    network_policy     = "cilium"

    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"

    pod_cidr       = var.pod_cidr
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }

  tags = var.tags
}

