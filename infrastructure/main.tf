# Create the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create the Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

# Enable Static Website 
resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.sa.id
  index_document     = "index.html"
}

data "azurerm_storage_container" "web" {
  name                = "$web"
  storage_account_id  = azurerm_storage_account.sa.id
  depends_on          = [azurerm_storage_account_static_website.static_site]
}

# Upload the index.html file to the hidden $web container
resource "azurerm_storage_blob" "index_html" {
  name                  = "index.html"
  storage_container_id  = data.azurerm_storage_container.web.id
  type                  = "Block"
  content_type          = "text/html"
  source                = "../index.html"
}

# Create the CDN Profile
resource "azurerm_cdn_profile" "cdn" {
  name                = var.cdn_profile_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
}

# Create the CDN Endpoint pointing to Blob Storage
resource "azurerm_cdn_endpoint" "endpoint" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.cdn.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Enforce HTTPS by blocking HTTP traffic
  is_http_allowed  = false
  is_https_allowed = true

  origin {
    name      = "primary-storage"
    host_name = azurerm_storage_account.sa.primary_web_host
  }

  origin_host_header = azurerm_storage_account.sa.primary_web_host
}

/* 
  STAGE 2: KEEP THIS COMMENTED OUT FOR NOW.
  Uncomment this after the DNS CNAME record is created.

resource "azurerm_cdn_endpoint_custom_domain" "custom_domain" {
  name            = "jakub-custom-domain"
  cdn_endpoint_id = azurerm_cdn_endpoint.endpoint.id
  host_name       = var.custom_domain_name

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}
*/