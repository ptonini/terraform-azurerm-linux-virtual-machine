locals {
  extra_disks = { for disk in flatten([
    for host_index in range(var.host_count) : [
      for k, v in var.extra_disks : {
        basename             = k
        fullname             = "${var.rg.name}-${var.name}${format("%04.0f", host_index + 1)}-${k}"
        host_index           = host_index
        storage_account_type = v["storage_account_type"]
        disk_size_gb         = v["disk_size_gb"]
      }
    ]
  ]) : disk.fullname => disk }
}

module "security_group" {
  source        = "ptonini/network-security-group/azurerm"
  version       = "~> 1.0.2"
  name          = "${var.rg.name}-${var.name}"
  rg            = var.rg
  network_rules = var.network_rules

}

module "network_interface" {
  source            = "ptonini/network-interface/azurerm"
  version           = "~> 1.0.3"
  count             = var.host_count
  name              = "${var.rg.name}-${var.name}${format("%04.0f", count.index + 1)}"
  rg                = var.rg
  subnet_id         = var.subnet_id
  public_ip         = var.public_access
  security_group_id = module.security_group.this.id
}

resource "azurerm_availability_set" "this" {
  count               = var.high_availability ? 1 : 0
  name                = "${var.rg.name}-${var.name}"
  resource_group_name = var.rg.name
  location            = var.rg.location
  managed             = true
}

resource "azurerm_linux_virtual_machine" "this" {
  count               = var.host_count
  name                = "${var.rg.name}-${var.name}${format("%04.0f", count.index + 1)}"
  location            = var.rg.location
  resource_group_name = var.rg.name
  size                = var.size
  admin_username      = coalesce(var.admin_username, "${var.name}-admin")
  availability_set_id = try(azurerm_availability_set.this[0].id, null)
  network_interface_ids = [
    module.network_interface[count.index].this.id
  ]
  source_image_id = var.source_image_id
  max_bid_price   = var.max_bid_price
  priority        = var.priority
  eviction_policy = var.eviction_policy
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_key
  }
  os_disk {
    disk_size_gb         = var.os_disk_size_gb
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account.primary_blob_endpoint
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? {} : { 1 = var.source_image_reference }
    content {
      publisher = source_image_reference.value["publisher"]
      offer     = source_image_reference.value["offer"]
      sku       = source_image_reference.value["sku"]
      version   = source_image_reference.value["version"]
    }
  }
  dynamic "plan" {
    for_each = var.plan == null ? {} : { 1 = var.plan }
    content {
      name      = plan.value["name"]
      product   = plan.value["product"]
      publisher = plan.value["publisher"]
    }
  }
  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_virtual_machine_extension" "this" {
  for_each                   = var.extensions
  name                       = each.key
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = each.value.publisher
  type                       = each.value.type
  auto_upgrade_minor_version = each.value.auto_upgrade_minor_version
  type_handler_version       = each.value.type_handler_version
  settings                   = each.value.settings
  protected_settings         = each.value.protected_settings
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


module "extra_disks" {
  source                         = "ptonini/managed-disk/azurerm"
  version                        = "~> 1.0.2"
  for_each                       = local.extra_disks
  name                           = each.value["fullname"]
  rg                             = var.rg
  storage_account_type           = each.value["storage_account_type"]
  disk_size_gb                   = each.value["disk_size_gb"]
  virtual_machine_id             = azurerm_linux_virtual_machine.this[each.value["host_index"]].id
  virtual_machine_attachment_lun = 10 + index(keys(var.extra_disks), each.value["basename"])
  depends_on = [
    azurerm_linux_virtual_machine.this
  ]
}