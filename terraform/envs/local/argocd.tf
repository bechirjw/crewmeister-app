module "argocd" {
  source = "../../modules/kubernetes/argocd"

  chart_version = "10.11.6"
  values_file   = abspath("${path.module}/values/argocd.yaml")
}
