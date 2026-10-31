variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "loki_chart_version" {
  type = string
}

variable "alloy_chart_version" {
  type = string
}

variable "loki_values" {
  type = string
}

variable "alloy_values" {
  type = string
}
