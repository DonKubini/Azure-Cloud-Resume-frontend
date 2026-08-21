output "website_url" {
  description = "The primary web endpoint for the static website"
  value       = azurerm_storage_account.sa.primary_web_endpoint
}

output "cdn_endpoint_url" {
  description = "The Azure CDN Endpoint URL"
  value       = "https://${azurerm_cdn_endpoint.endpoint.fqdn}"
}