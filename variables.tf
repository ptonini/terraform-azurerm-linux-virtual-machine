variable "name" {}

variable "rg" {}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  default = ""
}

variable "ssh_key" {}

variable "public_access" {
  default = false
  type    = bool
}

variable "host_count" {
  type    = number
  default = 1
}

variable "size" {
  default = "Standard_B1s"
}

variable "source_image_reference" {
  default = null
}

variable "os_disk_size_gb" {
  default = 30
}

variable "source_image_id" {
  default = null
}

variable "plan" {
  default = null
}

variable "snapshot" {
  type    = string
  default = "true"
}

variable "extra_disks" {
  type = map(object({
    storage_account_type = string
    disk_size_gb         = string
  }))
  default = {}
}

variable "network_rules" {
  default = {}
}

variable "tags" {
  default = {}
}

variable "high_availability" {
  type    = bool
  default = false
}

variable "boot_diagnostics_storage_account" {}

variable "sku_tier" {
  default = "Standard"
}

variable "identity_type" {
  default = "SystemAssigned"
}

variable "identity_ids" {
  type    = list(string)
  default = null
}

variable "priority" {
  default = "Regular"
}

variable "max_bid_price" {
  default = -1
}

variable "eviction_policy" {
  default = null
}

variable "extensions" {
  type = map(object({
    publisher                  = string
    type                       = string
    auto_upgrade_minor_version = optional(bool, true)
    type_handler_version       = string
    settings                   = optional(string)
    protected_settings         = optional(string)
  }))
  default = {}
}