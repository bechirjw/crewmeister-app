variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "system_vm_size" {
  type = string
}

variable "system_node_count" {
  type    = number
  default = 1

  validation {
    condition     = var.system_node_count >= 1
    error_message = "AKS requires at least two system nodes."
  }
}

variable "os_disk_size_gb" {
  type    = number
  default = 32
}

variable "aks_subnet_id" {
  type    = string
  default = null
}

variable "identity_ids" {
  type    = list(string)
  default = []
}

variable "service_cidr" {
  type = string
}

variable "dns_service_ip" {
  type = string
}

variable "pod_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}
