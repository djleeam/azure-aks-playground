terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
  subscription_id = "bc731e26-cf40-4dec-8360-0c422883cdb8"
}