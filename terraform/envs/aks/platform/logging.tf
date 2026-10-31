
module "logging" {
  count  = var.enable_logging ? 1 : 0
  source = "../../../modules/kubernetes/logging"

  namespace = "monitoring"

  loki_chart_version  = "18.5.0"
  alloy_chart_version = "1.14.3"

  loki_values = file(
    "${path.module}/values/loki.yaml"
  )

  alloy_values = file(
    "${path.module}/values/alloy.yaml"
  )

  depends_on = [module.monitoring]
}
