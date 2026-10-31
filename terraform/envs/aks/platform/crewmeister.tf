
resource "helm_release" "crewmeister" {
  name             = "crewmeister"
  namespace        = "crewmeister"
  create_namespace = true

  chart = abspath(
    "${path.module}/../../../../helm/crewmeister"
  )

  values = [
    file(
      "${path.module}/../../../../helm/crewmeister/values-aks.yaml"
    )
  ]

  dependency_update = true

  wait    = true
  atomic  = true
  timeout = 900

  depends_on = [
    module.monitoring,
    module.logging
  ]
}
