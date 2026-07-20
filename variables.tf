# Define the target Azure region for deployment
variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "Switzerland North"
}

# Project identifier used for resource naming conventions
variable "project" {
  description = "Project codename for resource tagging and naming"
  type        = string
  default     = "vault"
}

# Environment context (prod, staging, dev) for lifecycle management
variable "environment" {
  description = "The deployment environment context"
  type        = string
  default     = "prod"
}
