locals {
  # Resource naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Zone for zonal resources (derived from bootstrap region)
  zone = "${local.region}-a"

  # Common labels
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # GKE workload identity pool
  workload_identity_pool = "${local.project_id}.svc.id.goog"

  # Artifact Registry repository URL
  artifact_registry_url = "${local.region}-docker.pkg.dev/${local.project_id}/${var.project_name}-repo"

  # Kubernetes namespaces
  k8s_namespace = "app"

  # Service names
  services = {
    api_core    = "api-core"
    api_usage   = "api-usage"
    api_message = "api-message"
    batch_core  = "batch-core"
  }
}
