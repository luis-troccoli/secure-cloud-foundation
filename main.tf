# Create the primary Resource Group to house all foundation assets
resource "azurerm_resource_group" "foundation" {
  name     = "rg-${var.project}-${var.environment}-001"
  location = var.location
}

# Define the Virtual Network (VNet) for secure internal communication
resource "azurerm_virtual_network" "foundation_vnet" {
  name                = "vnet-${var.project}-${var.environment}-001"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.foundation.location
  resource_group_name = azurerm_resource_group.foundation.name
}

# The primary subnet within the network
resource "azurerm_subnet" "foundation_subnet" {
  name                 = "snet-internal-${var.project}-${var.environment}-001"
  resource_group_name  = azurerm_resource_group.foundation.name
  virtual_network_name = azurerm_virtual_network.foundation_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Link the NSG to the subnet -- without this association, the NSG rules
# in security.tf are defined but never actually enforced on any traffic.
resource "azurerm_subnet_network_security_group_association" "nsg_link" {
  subnet_id                 = azurerm_subnet.foundation_subnet.id
  network_security_group_id = azurerm_network_security_group.foundation_nsg.id
}
