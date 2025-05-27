# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateschemata"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }

  required_version = "1.11.4"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  use_oidc        = true
  subscription_id = var.subscription_id
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = ["evgblobtrig", "demo", var.location]
}

# Resource group for the demo
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name
  location = var.location
}

# Storage account
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  name                = module.naming.storage_account.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  network_rules                 = null
  public_network_access_enabled = true

  containers = {
    demo_container = {
      name = "demo"
    }
  }
}

# Log analytics workspace
module "law" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  name                = module.naming.storage_account.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
}

# Application Insights for the Function App
module "appi" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.1.5"

  name                = module.naming.application_insights.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.law.resource_id
}

# App Service Plan for the Function App
module "asp" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "0.5.0"

  name                   = module.naming.app_service_plan.name
  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  os_type                = "Linux"
  sku_name               = "S1"
  worker_count           = 1
  zone_balancing_enabled = false
}

# Function App
module "function_app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.16.0"

  name                = module.naming.function_app.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "functionapp"

  os_type                  = module.asp.resource.os_type
  service_plan_resource_id = module.asp.resource_id

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  application_insights = {
    name                  = module.naming.application_insights.name
    workspace_resource_id = module.law.resource_id
  }
}
