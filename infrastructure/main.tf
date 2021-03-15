# Store state in Azure storage
terraform {
  backend "azurerm" {
    resource_group_name   = "tstate"
    storage_account_name  = "tstate09762"
    container_name        = "tstate"
    key                   = "terraform.tfstate"
  }
}

# Configure the Azure provider
provider "azurerm" { 
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    features {}
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure Region to deploy resources."
}

variable "domain" {
  type        = string
  default     = "ecomp"
}

variable "resourceGroupName" {
  type        = string
  default     = "rg-storage-dev-eus-01"
}

variable "storageAccountName" {
  type        = string
  default     = "devopslab"
}

variable "storageAccountType" {
  type        = string
  default     = "LRS"
}

variable "StorageAccountCount" {
  type        = number
  default     = 2
}

resource "azurerm_resource_group" "example" {
  name     = var.resourceGroupName
  location = var.location
}

resource "azurerm_storage_account" "example" {
  count                    = var.StorageAccountCount
  name                     = lower("${var.domain}${var.storageAccountName}${count.index}")
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = var.storageAccountType

  tags = {
    environment = "staging"
  }
}

output "storageAccounts" {
  value = [azurerm_storage_account.example.*.name]
}
