# From ARM Templates To Terraform
## A guide for developers

## Samples

### ARM Template
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "domain": {
            "type": "string",
            "defaultValue": "ecomp"
        },
        "storageAccountName": {
            "type": "string",
            "defaultValue": "devopslab"
        },
        "storageAccountType": {
            "type": "string",
            "defaultValue": "Standard_LRS"
        },
        "StorageAccountCount": {
            "type": "int",
            "defaultValue": 2
        }
    },
    "variables": {
    },
    "resources": [
        {
            "name": "[toLower(concat(parameters('domain'),parameters('storageAccountName'),copyIndex())))]",
            "copy": {
                "name": "storagecopy",
                "count": "[parameters('StorageAccountCount')]"
            },
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2015-06-15",
            "location": "[resourceGroup().location]",
            "properties": {
                "accountType": "[parameters('storageAccountType')]"
            }
        }
    ],
    "outputs": {
    }
}
```

### Sample Terraform

```terraform
# Store state in Azure storage
terraform {
  backend "azurerm" {
    resource_group_name   = "tstate"
    storage_account_name  = "tstate09762"
    container_name        = "tstate"
    key                   = "terraform.tfstate"
  }
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure Region to deploy resources."
}

# Configure the Azure provider
provider "azurerm" { 
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
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
  description = "The Azure Region to deploy resources."
}

variable "resourceGroupName" {
  type        = string
  default     = "rg-storage-dev-eus-01"
  description = "The Azure Region to deploy resources."
}

variable "storageAccountName" {
  type        = string
  default     = "devopslab"
  description = "The Azure Region to deploy resources."
}

variable "storageAccountType" {
  type        = string
  default     = "Standard_LRS"
  description = "The Azure Region to deploy resources."
}

variable "StorageAccountCount" {
  type        = int
  default     = 2
  description = "The Azure Region to deploy resources."
}

resource "azurerm_resource_group" "example" {
  name     = var.resourceGroupName
  location = var.location
}

resource "azurerm_storage_account" "example" {
  count                    = var.StorageAccountCount
  name                     = lower("${var.domain}${var.storageAccountName}.${count.index}")
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = var.storageAccountType

  tags = {
    environment = "staging"
  }
}
```


## Common

- Parameters
- Variables
- Resources
- Outputs
- Templates/modules
- Built-in functions


## Unique to terraform

- Providers: interact with remote systems. Each provider adds a set of resource types and/or data sources that Terraform can manage.
- State:

## Terraform deployment phases

### Init

terraform init

### Plan

terrform plan

### Apply

terraform apply
