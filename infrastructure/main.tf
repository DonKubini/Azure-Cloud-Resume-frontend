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
  content_md5           = filemd5("../index.html")
}