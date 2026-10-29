resource "kubernetes_namespace_v1" "crewmeister" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "crewmeister"
      "environment"               = "local"
    }
  }
}
