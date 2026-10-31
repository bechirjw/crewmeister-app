resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana-community.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [var.loki_values]
}

resource "helm_release" "alloy" {
  name             = "alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  version          = var.alloy_chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [var.alloy_values]

  depends_on = [helm_release.loki]
}
