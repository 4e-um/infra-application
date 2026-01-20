# =============================================================================
# Terraform Cloud Configuration
# =============================================================================

variable "terraform_cloud_org" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "bootstrap_workspace_name" {
  description = "Bootstrap workspace name in Terraform Cloud"
  type        = string
  default     = "infra-bootstrap"
}

# =============================================================================
# Project Configuration
# =============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "telecom-app"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "database_tier" {
  description = "CloudSQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_disk_size" {
  description = "CloudSQL disk size in GB"
  type        = number
  default     = 10
}

# =============================================================================
# Redis Configuration
# =============================================================================

variable "redis_usage_password" {
  description = "Redis password for usage service"
  type        = string
  sensitive   = true
}

variable "redis_message_password" {
  description = "Redis password for message service"
  type        = string
  sensitive   = true
}

variable "redis_machine_type" {
  description = "Machine type for Redis VMs"
  type        = string
  default     = "e2-micro"
}

# =============================================================================
# Kafka Configuration (Confluent Cloud)
# =============================================================================

variable "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  type        = string
}

variable "kafka_api_key" {
  description = "Kafka API key"
  type        = string
  sensitive   = true
}

variable "kafka_api_secret" {
  description = "Kafka API secret"
  type        = string
  sensitive   = true
}

# =============================================================================
# Cloudflare Configuration
# =============================================================================

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

# =============================================================================
# Cloud Run Job Configuration
# =============================================================================

variable "batch_cpu_limit" {
  description = "CPU limit for batch job"
  type        = string
  default     = "2"
}

variable "batch_memory_limit" {
  description = "Memory limit for batch job"
  type        = string
  default     = "2Gi"
}

variable "batch_timeout" {
  description = "Timeout for batch job"
  type        = string
  default     = "3600s"
}

# =============================================================================
# Application Secrets
# =============================================================================

variable "aes_secret_key" {
  description = "AES secret key for encryption (32 characters)"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# GitHub Actions Configuration
# =============================================================================

variable "github_org" {
  description = "GitHub organization name for Workload Identity Federation"
  type        = string
  default     = "4e-um"
}

variable "github_repos" {
  description = "List of GitHub repository names allowed to authenticate"
  type        = list(string)
  default     = ["api-core", "api-usage", "api-message", "batch-core"]
}
