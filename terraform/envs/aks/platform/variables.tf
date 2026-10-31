
variable "enable_monitoring" {
  description = "Enable monitoring stack on AKS"
  type        = bool
  default     = false
}
variable "enable_logging" {
  type    = bool
  default = false
}
