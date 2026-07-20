terraform {
  required_providers {
    # Define the Azure provider to manage Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  # Features block is required for the Azure provider
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
