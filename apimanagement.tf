// Sample code for setting up a API Management and Azure Function app (API)
provider "azurerm" {
  features {}
}

variable "resource_group" {
    default = "demo-rg"
}

variable "prefix" {
    default = "l3moni-demo"
}

variable "company" {
    default = "l3moni-cafe"
}

resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "West Europe"

  tags = {
    "toBeDeleted" = "ifSeen"
  }
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_api_management" "api_management" {
  name                = "${var.prefix}-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.company
  publisher_email     = "example@example.com"

  sku_name = "Developer_1"

  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
    XML
  }
}

resource "azurerm_api_management_api" "example_api" {
  name                = "${var.prefix}-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.api_management.name
  revision            = "1"
  display_name        = "${var.prefix} API"
  path                = "example"
  protocols           = ["https"]

  import {
    content_format = "swagger-link-json"
    content_value  = "http://conferenceapi.azurewebsites.net/?format=json"
  }
}

resource "azurerm_api_management_logger" "apim_logger" {
  name                = "${var.prefix}-apimlogger"
  api_management_name = azurerm_api_management.api_management.name
  resource_group_name = azurerm_resource_group.rg.name

  application_insights {
    instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "api_diagnostic" {
  identifier = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azurerm_api_management.api_management.name
  api_name                 = azurerm_api_management_api.example_api.name
  api_management_logger_id = azurerm_api_management_logger.apim_logger.id

  sampling_percentage       = 5.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}

