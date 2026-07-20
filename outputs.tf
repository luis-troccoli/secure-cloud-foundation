# Output the Resource Group ID for external reference/monitoring
output "resource_group_id" {
  description = "The unique identifier of the foundation Resource Group"
  value       = azurerm_resource_group.foundation.id
}

# Output the VNet ID to allow peering or integration with other modules
output "vnet_id" {
  description = "The unique identifier of the Virtual Network"
  value       = azurerm_virtual_network.foundation_vnet.id
}

# Output the Key Vault URI for application-side secret integration
output "key_vault_uri" {
  description = "The URI endpoint for the Azure Key Vault"
  value       = azurerm_key_vault.foundation_kv.vault_uri
}

# Output the NSG ID for audit and compliance checks
output "nsg_id" {
  description = "The unique identifier of the Security Group"
  value       = azurerm_network_security_group.foundation_nsg.id
}
