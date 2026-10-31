data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "this" {
  count = var.enabled ? 1 : 0

  name            = var.name
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.amount
  time_grain = "Monthly"

  time_period {
    start_date = var.time_period_start
  }

  dynamic "notification" {
    for_each = var.notifications

    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_roles  = notification.value.contact_roles
    }
  }
}
