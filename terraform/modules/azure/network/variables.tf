variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "aks_subnet_prefix" {
  type = string
}

variable "appgw_subnet_prefix" {
  type    = string
  default = null
}

variable "create_appgw_subnet" {
  type    = bool
  default = false
}

variable "tags" {
  type = map(string)
}
