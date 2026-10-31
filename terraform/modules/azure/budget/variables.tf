variable "enabled" {
  type = bool
}

variable "name" {
  type = string
}

variable "amount" {
  type = number
}

variable "time_period_start" {
  type = string
}

variable "notifications" {
  type = list(object({
    enabled        = bool
    threshold      = number
    operator       = string
    threshold_type = string
    contact_emails = list(string)
    contact_roles  = list(string)
  }))

  default = []
}
