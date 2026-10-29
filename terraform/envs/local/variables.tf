variable "kubeconfig_path" {
  description = "Kubeconfig du cluster Kubernetes VMware"
  type        = string
  default     = "~/.kube/crewmeister-admin.conf"
}

variable "namespace" {
  description = "Namespace de l'application Crewmeister"
  type        = string
  default     = "crewmeister"
}
