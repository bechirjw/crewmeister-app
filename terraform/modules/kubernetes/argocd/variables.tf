variable "chart_version" {
  description = "Version du Helm chart Argo CD"
  type        = string
}

variable "values_file" {
  description = "Fichier de configuration Helm"
  type        = string
}
