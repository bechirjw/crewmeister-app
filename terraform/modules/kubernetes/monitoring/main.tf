resource "helm_release" "monitoring" {
  name             = "monitoring"
  namespace        = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  values = [
    file(var.values_file)
  ]

  wait          = true
  wait_for_jobs = true
  atomic        = true
  timeout       = 900
}
