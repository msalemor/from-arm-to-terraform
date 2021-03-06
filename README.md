# Terraform for ARM developers

## Sample code

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

Main file: main.tf

```bash
az group create \
    --name rg-tfstate-eus-dev \
    --location eastus
    
az storage account create \
    --name mydomaintfstate \
    --resource-group storage-resource-group \
    --location eastus \
    --sku Standard_LRS \
    --kind StorageV2    
    
az storage container create -n mydomaintfstate    
```

```terraform
# Store state in Azure storage
terraform {
  backend "azurerm" {
    resource_group_name   = "rg-tfstate-eus-dev"
    storage_account_name  = "mydomaintfstate"
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
```

Variable file: 

dev.tfvars

```bash
StorageAccountCount=3
```

qa.tfvars

```bash
StorageAccountCount=3
storageAccountType=GRS
```

## ARM and Terraform common concepts

- Parameters in ARM/Variables in Terraform
- Resources
- Outputs
- Built-in functions

## Terraform concepts

- State: It consists of cached information about the infrastructure managed by Terraform and the related configurations.
- Provider: It is a plugin to interact with APIs of service and access its related resources.
- Module: It is a folder with Terraform templates where all the configurations are defined
- Data Source: It is implemented by providers to return information on external objects to terraform.
- Variables: Also used as input-variables, it is key-value pair used by Terraform modules to allow customization.
- Resources: It refers to a block of one or more infrastructure objects (compute instances, virtual networks, etc.), which are used in configuring and managing the infrastructure.
- Output Values: These are return values of a terraform module that can be used by other configurations.
- Plan: It is one of the stages where it determines what needs to be created, updated, or destroyed to move from real/current state of the infrastructure to the desired state.
- Apply: It is one of the stages where it applies the changes real/current state of the infrastructure in order to move to the desired state.

> Note: Please see references below

## Terraform deployment phases

### Init

```bash
terraform init
```

### Plan

```bash
terrform plan -var-file=dev.tfvars [-out=main.tfstate]
```

### Apply

```bash
terraform apply -var-file=dev.tfvars [main.tfstate]

# Generates terraform.tfstate
```

### Destoy

```bash
terraform destoy
```

### Workspaces

- [Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)


## Terraform ADO yaml pipeline

```terraform
# this line is imported so that backend connection is extablished in 
the pipeline
terraform {
  backend "azurerm" {
    resource_group_name   = "tstate"
    storage_account_name  = "tstate2021"
    container_name        = "tstate"
    key                   = "terraform.tfstate"
  }
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}
resource "azurerm_app_service_plan" "test" {
  name                = "azure-functions-test-service-plan"
  location            = "westeurope"
  resource_group_name = "resource_group_name"
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
resource "azurerm_application_insights" "test" {
  name                = "miel-test-terraform-insights"
  location            = "westeurope"
  resource_group_name = "resource_group_name"
  application_type    = "web"
}
resource "azurerm_function_app" "test" {
  name                      = "miel-test-terraform"
  location                  = "westeurope"
  resource_group_name       = "resource_group_name"
  app_service_plan_id       = azurerm_app_service_plan.test.id
  storage_connection_string = "storage_connection_string"
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.test.instrumentation_key
  }
}
```

```yaml
trigger:
- master
pool:
  vmImage: 'ubuntu-latest'
steps:
- task: TerraformTaskV1@0
  displayName: Terra Init
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: $(System.DefaultWorkingDirectory)
    backendServiceArm: 'ServiceConnectionName'
    backendAzureRmResourceGroupName: 'common-services-miel'
    backendAzureRmStorageAccountName: 'mielstorage001'
    backendAzureRmContainerName: 'configman'
    backendAzureRmKey: 'tf/terraform.tfstate'
- task: TerraformTaskV1@0
  displayName: Terra Destroy
  inputs:
    provider: 'azurerm'
    command: 'destroy'
    workingDirectory: $(System.DefaultWorkingDirectory)
    environmentServiceNameAzureRM: 'ServiceConnectionName'
- task: TerraformTaskV1@0
  displayName: Terra Plan
  inputs:
    provider: 'azurerm'
    command: 'plan'
    workingDirectory: $(System.DefaultWorkingDirectory)
    environmentServiceNameAzureRM: 'ServiceConnectionName'
- task: TerraformTaskV1@0
  displayName: Terra Apply
  inputs:
    provider: 'azurerm'
    command: 'apply'
    workingDirectory: $(System.DefaultWorkingDirectory)
    environmentServiceNameAzureRM: 'ServiceConnectionName'
```

## Reference

- [Terraform for beginners](https://geekflare.com/terraform-for-beginners/)
- [ADO Terraform sample](https://mthai.medium.com/how-to-run-terraform-tasks-in-azure-devops-273935089536)
