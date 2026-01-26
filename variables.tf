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
  default     = "db-custom-6-5632"
}

variable "database_disk_size" {
  description = "CloudSQL disk size in GB"
  type        = number
  default     = 30
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

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (required for Workers)"
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
  default     = "6"
}

variable "batch_memory_limit" {
  description = "Memory limit for batch job"
  type        = string
  default     = "8Gi"
}

variable "batch_timeout" {
  description = "Timeout for batch job"
  type        = string
  default     = "7200s"
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

variable "ureca_secret_key" {
  description = "Ureca secret key for api-core encryption"
  type        = string
  sensitive   = true
}

variable "ureca_hash_key" {
  description = "Ureca hash key for api-core"
  type        = string
  sensitive   = true
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
  default     = ["api-core", "api-usage", "api-message", "api-mock", "batch-core", "fn-batch-control"]
}

# =============================================================================
# Cloud Run Service Configuration
# =============================================================================

variable "api_cpu_limit" {
  description = "CPU limit for API services"
  type        = string
  default     = "2"
}

variable "api_memory_limit" {
  description = "Memory limit for API services"
  type        = string
  default     = "1Gi"
}

variable "api_min_instances" {
  description = "Minimum instances for API services"
  type        = number
  default     = 1
}

variable "api_max_instances" {
  description = "Maximum instances for API services"
  type        = number
  default     = 10
}

variable "api_concurrency" {
  description = "Max concurrent requests per instance"
  type        = number
  default     = 80
}

# =============================================================================
# OpenTelemetry Configuration
# =============================================================================

variable "otel_exporter_endpoint" {
  description = "OTLP exporter endpoint (Alloy external IP)"
  type        = string
  default     = ""
}

variable "otel_enabled" {
  description = "Enable OpenTelemetry instrumentation"
  type        = bool
  default     = false
}

# =============================================================================
# Mock Server Configuration
# =============================================================================

variable "mock_server_enabled" {
  description = "Enable mock server for api-message (uses mock.{domain_name})"
  type        = bool
  default     = false
}

# =============================================================================
# Billing Dashboard Configuration (api-core)
# =============================================================================

variable "billing_grafana_iframe_url" {
  description = "Grafana iframe URL for billing dashboard"
  type        = string
  default     = ""
}

variable "billing_grafana_refresh_interval" {
  description = "Grafana dashboard refresh interval"
  type        = string
  default     = "5s"
}

# =============================================================================
# Cloud Function Configuration (api-core)
# =============================================================================

variable "cloud_function_base_url" {
  description = "Cloud Function base URL for batch control"
  type        = string
  default     = ""
}

# =============================================================================
# Cloud Function Configuration (fn-batch-control)
# =============================================================================

variable "fn_batch_control_cpu_limit" {
  description = "CPU limit for fn-batch-control"
  type        = string
  default     = "1"
}

variable "fn_batch_control_memory_limit" {
  description = "Memory limit for fn-batch-control"
  type        = string
  default     = "512Mi"
}

variable "fn_batch_control_max_instances" {
  description = "Maximum instances for fn-batch-control"
  type        = number
  default     = 100
}

variable "fn_batch_control_concurrency" {
  description = "Max concurrent requests per instance"
  type        = number
  default     = 1
}

variable "fn_batch_control_timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 60
}

# =============================================================================
# Cloud Tasks Configuration (batch-queue)
# =============================================================================
# Job 실행 중이면 503 반환 → Cloud Tasks 재시도
# 장시간 Job 대비 충분한 재시도 설정

variable "batch_queue_max_attempts" {
  description = "Maximum retry attempts for failed tasks (503 retries for running jobs)"
  type        = number
  default     = 100
}

variable "batch_queue_min_backoff" {
  description = "Minimum backoff time in seconds between retries"
  type        = number
  default     = 30
}

variable "batch_queue_max_backoff" {
  description = "Maximum backoff time in seconds between retries"
  type        = number
  default     = 300
}

variable "batch_queue_max_retry_duration" {
  description = "Maximum duration in seconds for retrying a task (2 hours for long jobs)"
  type        = number
  default     = 7200
}

