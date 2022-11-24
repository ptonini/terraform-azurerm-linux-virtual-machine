output "this" {
  value = azurerm_linux_virtual_machine.this
}

output "network_interfaces" {
  value = [for ni in module.network_interface : ni.this]
}

output "public_ips" {
  value = [for ni in module.network_interface : ni["public_ip"]]
}