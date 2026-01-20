# =============================================================================
# GKE Outputs
# =============================================================================

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${local.region} --project ${local.project_id}"
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

output "cloudsql_private_ip" {
  description = "CloudSQL private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

output "cloudsql_database_name" {
  description = "CloudSQL database name"
  value       = google_sql_database.main.name
}

# =============================================================================
# Redis Outputs
# =============================================================================

output "redis_usage_private_ip" {
  description = "Redis usage instance private IP"
  value       = module.redis_usage.private_ip
}

output "redis_usage_external_ip" {
  description = "Redis usage instance external IP"
  value       = module.redis_usage.external_ip
}

output "redis_message_private_ip" {
  description = "Redis message instance private IP"
  value       = module.redis_message.private_ip
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
# Cloud Run Job Outputs
# =============================================================================

output "cloudrun_job_name" {
  description = "Cloud Run Job name"
  value       = google_cloud_run_v2_job.batch_core.name
}

# =============================================================================
# Service Account Outputs
# =============================================================================

output "gke_workload_sa_email" {
  description = "GKE Workload Identity service account email"
  value       = google_service_account.gke_workload.email
}

output "batch_sa_email" {
  description = "Batch job service account email"
  value       = google_service_account.batch.email
}

# =============================================================================
# VPC Connector Output
# =============================================================================

output "vpc_connector_id" {
  description = "VPC Access Connector ID"
  value       = google_vpc_access_connector.serverless.id
}

# =============================================================================
# Load Balancer Output
# =============================================================================

output "load_balancer_ip" {
  description = "Global Load Balancer IP address"
  value       = google_compute_global_address.lb.address
}

# =============================================================================
# DNS Output
# =============================================================================

output "api_domain" {
  description = "API domain name"
  value       = "api.${var.domain_name}"
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
