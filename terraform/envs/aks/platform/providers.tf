
provider "kubernetes" {
  config_path    = pathexpand("~/.kube/crewmeister-aks")
  config_context = "crewmeister-aks-student"
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand("~/.kube/crewmeister-aks")
    config_context = "crewmeister-aks-student"
  }
}
