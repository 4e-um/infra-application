# =============================================================================
# IAM Bindings (Unified for Dev)
# =============================================================================
# All permissions granted to single 'app' service account

# -----------------------------------------------------------------------------
# App Service Account Permissions
# -----------------------------------------------------------------------------

# CloudSQL Client
resource "google_project_iam_member" "app_cloudsql" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Secret Manager access
resource "google_project_iam_member" "app_secrets" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Artifact Registry Reader
resource "google_project_iam_member" "app_artifact_registry" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Cloud Run Invoker (for scheduler to trigger jobs)
resource "google_project_iam_member" "app_run_invoker" {
  project = local.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Monitoring Writer
resource "google_project_iam_member" "app_monitoring" {
  project = local.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Logging Writer
resource "google_project_iam_member" "app_logging" {
  project = local.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Trace Writer
resource "google_project_iam_member" "app_trace" {
  project = local.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# -----------------------------------------------------------------------------
# Workload Identity Binding
# -----------------------------------------------------------------------------

resource "google_service_account_iam_binding" "app_workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${local.project_id}.svc.id.goog[${local.k8s_namespace}/app]",
  ]

  depends_on = [google_container_cluster.main]
}
