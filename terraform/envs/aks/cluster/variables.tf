
variable "subscription_id" {
  description = "Azure for Students subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure deployment region"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "student"
}

variable "system_vm_size" {
  description = "AKS system node VM size"
  type        = string
  default     = "Standard_D4as_v5"
}

variable "system_node_count" {
  description = "Number of AKS system nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.system_node_count >= 1
    error_message = "AKS system node pool requires at least 2 nodes."
  }
}

variable "create_custom_network" {
  description = "Create a custom VNet for AKS"
  type        = bool
  default     = true
}

variable "enable_budget" {
  description = "Enable Azure subscription budget"
  type        = bool
  default     = false
}

variable "budget_amount" {
  description = "Monthly budget amount"
  type        = number
  default     = 20
}

variable "budget_start" {
  description = "Budget start date"
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "budget_contact_emails" {
  description = "Budget notification emails"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Azure resource tags"
  type        = map(string)

  default = {
    project     = "crewmeister"
    environment = "student"
    managed_by  = "terraform"
  }
}
