terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Local backend by default (state file stays on your machine).
  # For a "real enterprise" story, migrate this to an azurerm backend
  # (storage account + container) once you've proven the pipeline works.
  # Uncomment and fill in after creating the storage account manually:
  #
backend "azurerm" {
     resource_group_name  = "tfstate-rg"
     storage_account_name = "tfstateadeptask"     
     container_name       = "tfstate-task"
     key                  = "aks.terraform.tfstate"
   }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}
