resource "helm_release" "local_path" {
  name             = "local-path-provisioner"
  namespace        = "local-path-storage"
  create_namespace = true

  chart   = "oci://ghcr.io/rancher/local-path-provisioner/charts/local-path-provisioner"
  version = "0.0.37"

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      storageClass = {
        create            = true
        name              = "local-path"
        defaultClass      = false
        reclaimPolicy     = "Retain"
        volumeBindingMode = "WaitForFirstConsumer"
      }
    })
  ]
}
