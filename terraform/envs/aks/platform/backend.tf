terraform {
  backend "azurerm" {
    resource_group_name  = "rg-crew-student-tfstate"
    storage_account_name = "stcrewstate25ea93cc4a"
    container_name       = "tfstate"
    key                  = "aks/platform.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }
}
