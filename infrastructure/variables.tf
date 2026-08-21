variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "The name of the Resource Group"
  type        = string
  default     = "cloud-resume-rg"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase letters/numbers)"
  type        = string
  default     = "jscloudresumeacct2026" 
}