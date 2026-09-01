output "website_url" {
  description = "The primary web endpoint for the static website"
  value       = azurerm_storage_account.sa.primary_web_endpoint
}

output "AZURE_CLIENT_ID" {
  value = azurerm_user_assigned_identity.github_frontend_identity.client_id
}
output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}
output "AZURE_SUBSCRIPTION_ID" {
  value = data.azurerm_client_config.current.subscription_id
}