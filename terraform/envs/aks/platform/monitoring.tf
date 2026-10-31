
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "../../../modules/kubernetes/monitoring"

  chart_version = "92.14.0"
  values_file   = abspath("${path.module}/values/monitoring.yaml")
}

