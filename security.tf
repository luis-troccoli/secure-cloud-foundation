# Network Security Group: default-deny in both directions, not just inbound.
# Azure allows all outbound traffic by default unless explicitly restricted --
# a "hardened" or "Zero Trust" posture must lock down both directions.
resource "azurerm_network_security_group" "foundation_nsg" {
  name                = "nsg-${var.project}-${var.environment}-001"
  location            = azurerm_resource_group.foundation.location
  resource_group_name = azurerm_resource_group.foundation.name

  # --- INBOUND ---
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInBound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # --- OUTBOUND ---
  security_rule {
    name                       = "AllowHttpsOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllOutBound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Azure Key Vault: centralized and encrypted secret storage, hardened.
resource "azurerm_key_vault" "foundation_kv" {
  name                = "kv-${var.project}-${var.environment}-01"
  location            = azurerm_resource_group.foundation.location
  resource_group_name = azurerm_resource_group.foundation.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Without this, anyone with delete permission can permanently destroy
  # the vault and its secrets before the soft-delete window expires.
  purge_protection_enabled = true

  # RBAC-based access control (modern approach vs. legacy access_policy blocks)
  enable_rbac_authorization = true

  # Public network access disabled. Terraform can still create and manage
  # this vault (name, RBAC, network_acls, etc.) from a GitHub-hosted
  # runner because those operations go through the Azure Resource Manager
  # control plane, not through the vault's own data-plane endpoint. This
  # only matters if something needs to read/write secrets directly against
  # the vault's DNS endpoint -- which nothing in this lab does yet.
  public_network_access_enabled = false

  # Firewall: explicit default-deny, defense in depth even with public
  # access already disabled above.
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# Grant the deploying identity (the OIDC-federated CI principal, or you
# during manual apply) permission to manage secrets. Without this, the
# vault exists but nothing has permission to read or write to it.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.foundation_kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Retrieve current Azure Client configuration for Tenant ID binding
data "azurerm_client_config" "current" {}
