output "website_url" {
  description = "The primary web endpoint for the static website"
  value       = azurerm_storage_account.sa.primary_web_endpoint
}