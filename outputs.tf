# =============================================================================
# Cloud Run Service Outputs
# =============================================================================

output "cloudrun_api_core_url" {
  description = "Cloud Run api-core service URL (public)"
  value       = google_cloud_run_v2_service.api_core.uri
}

output "cloudrun_api_usage_url" {
  description = "Cloud Run api-usage service URL (internal)"
  value       = google_cloud_run_v2_service.api_usage.uri
}

output "cloudrun_api_message_url" {
  description = "Cloud Run api-message service URL (internal)"
  value       = google_cloud_run_v2_service.api_message.uri
}

output "cloudrun_api_mock_url" {
  description = "Cloud Run api-mock service URL (public)"
  value       = google_cloud_run_v2_service.api_mock.uri
}

# =============================================================================
# Cloud Run Job Outputs
# =============================================================================

output "cloudrun_job_name" {
  description = "Cloud Run Job name"
  value       = google_cloud_run_v2_job.batch_core.name
}

# =============================================================================
# CloudSQL Outputs
# =============================================================================

output "cloudsql_instance_name" {
  description = "CloudSQL instance name"
  value       = google_sql_database_instance.main.name
}

output "cloudsql_connection_name" {
  description = "CloudSQL connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "cloudsql_public_ip" {
  description = "CloudSQL public IP address (experimental)"
  value       = google_sql_database_instance.main.public_ip_address
}

output "cloudsql_private_ip" {
  description = "CloudSQL private IP address (for VPC internal access)"
  value       = google_sql_database_instance.main.private_ip_address
}

output "cloudsql_database_name" {
  description = "CloudSQL database name"
  value       = google_sql_database.main.name
}

# =============================================================================
# Redis Outputs
# =============================================================================

output "redis_usage_external_ip" {
  description = "Redis usage instance external IP"
  value       = module.redis_usage.external_ip
}

output "redis_message_external_ip" {
  description = "Redis message instance external IP"
  value       = module.redis_message.external_ip
}

# =============================================================================
# Artifact Registry Outputs
# =============================================================================

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

# =============================================================================
# Service Account Output
# =============================================================================

output "app_sa_email" {
  description = "Unified app service account email"
  value       = google_service_account.app.email
}

# =============================================================================
# DNS Output
# =============================================================================

output "api_domain" {
  description = "API domain name"
  value       = "api.${var.domain_name}"
}

output "mock_domain" {
  description = "Mock API domain name"
  value       = "mock.${var.domain_name}"
}

# =============================================================================
# GitHub Actions Outputs (conditional - only when github_org is set)
# =============================================================================

output "github_actions_sa_email" {
  description = "GitHub Actions service account email"
  value       = local.github_enabled ? google_service_account.github_actions[0].email : null
}

output "github_actions_workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = local.github_enabled ? google_iam_workload_identity_pool_provider.github[0].name : null
}

output "github_actions_config" {
  description = "GitHub Actions workflow configuration snippet"
  value = local.github_enabled ? join("\n", [
    "# Add to your GitHub Actions workflow:",
    "- uses: google-github-actions/auth@v2",
    "  with:",
    "    workload_identity_provider: '${google_iam_workload_identity_pool_provider.github[0].name}'",
    "    service_account: '${google_service_account.github_actions[0].email}'"
  ]) : null
}
