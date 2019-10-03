output "vm_ids" {
  description = "Virtual machine ids created."
  value       = "${azurerm_virtual_machine.effortlessvm.*.id}"
}

output "network_security_group_id" {
  description = "id of the security group provisioned"
  value       = "${azurerm_network_security_group.effortlessnsg.id}"
}

output "network_interface_ids" {
  description = "ids of the vm nics provisoned."
  value       = "${azurerm_network_interface.effortlessnic.*.id}"
}

output "network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = "${azurerm_network_interface.effortlessnic.*.private_ip_address}"
}

output "public_ip_id" {
  description = "id of the public ip address provisoned."
  value       = "${azurerm_public_ip.effortlesspublicip.*.id}"
}

output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = "${azurerm_public_ip.effortlesspublicip.ip_address}"
}

output "public_ip_address_fqdn" {
  description = "The actual fqdn allocated for the resource."
  value       = "${azurerm_public_ip.effortlesspublicip.fqdn}"
}