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

# These blocks manage the upload of the index.html file to the $web container in the storage account.
# This is commented out because the upload will be handled by GitHub Actions using the Managed Identity and OIDC Federation.
# Uncomment these blocks if you want to upload the index.html file directly from Terraform instead of using GitHub Actions.
/*
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
*/

## Fetch your current Azure tenant and subscription IDs automatically
data "azurerm_client_config" "current" {}

# 1. Create a Managed Identity specifically for the Frontend Actions
resource "azurerm_user_assigned_identity" "github_frontend_identity" {
  name                = "github-actions-identity-frontend"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 2. Give it permission to upload files into the Storage Account blobs
resource "azurerm_role_assignment" "github_blob_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_frontend_identity.principal_id
}

# 3. Create the OIDC Federation for the Frontend repo
resource "azurerm_federated_identity_credential" "github_oidc_frontend" {
  name                = "github-actions-federation-frontend"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_frontend_identity.id
  subject             = "repo:${var.github_repository}:ref:refs/heads/main"
}