module "monitoring" {
  source = "../../../modules/kubernetes/monitoring"

  chart_version = "92.14.0"
  values_file   = abspath("${path.module}/values/monitoring.yaml")
}
