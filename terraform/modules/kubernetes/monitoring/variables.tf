variable "chart_version" {
  description = "Version du chart kube-prometheus-stack"
  type        = string
}

variable "values_file" {
  description = "Fichier de configuration Helm pour le monitoring"
  type        = string
}
