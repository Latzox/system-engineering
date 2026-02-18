# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "tfstatei6wb5"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }

  required_version = ">= 0.14.9"
}
provider "azurerm" {
  features {}
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "appservice-rg-${random_integer.ri.result}"
  location = "switzerlandnorth"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "webapp-asp-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                  = "webapp-${random_integer.ri.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config { 
    minimum_tls_version = "1.2"
    app_command_line    = "node server.js"
  }
}

#  Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "source_control" {
  app_id                 = azurerm_linux_web_app.webapp.id
  repo_url               = ""
  branch                 = "main"
  use_manual_integration = true
}

resource "azurerm_source_control_token" "source_token" {
  type         = "GitHub"
  token        = var.github_token
  token_secret = var.github_token
}