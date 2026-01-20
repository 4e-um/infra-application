# =============================================================================
# IAM Bindings
# =============================================================================

# -----------------------------------------------------------------------------
# Batch Service Account Permissions
# -----------------------------------------------------------------------------

# CloudSQL Client access for batch jobs
resource "google_project_iam_member" "batch_cloudsql" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.batch.email}"
}

# Secret Manager access for batch jobs
resource "google_project_iam_member" "batch_secrets" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.batch.email}"
}

# Artifact Registry Reader for pulling images
resource "google_project_iam_member" "batch_artifact_registry" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.batch.email}"
}

# -----------------------------------------------------------------------------
# Scheduler Service Account Permissions
# -----------------------------------------------------------------------------

# Cloud Run Invoker for scheduler to trigger jobs
resource "google_project_iam_member" "scheduler_run_invoker" {
  project = local.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

# Allow scheduler to act as batch service account
resource "google_service_account_iam_member" "scheduler_act_as_batch" {
  service_account_id = google_service_account.batch.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.scheduler.email}"
}

# -----------------------------------------------------------------------------
# GKE Workload Service Account Permissions
# -----------------------------------------------------------------------------

# CloudSQL Client access for GKE workloads
resource "google_project_iam_member" "gke_workload_cloudsql" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Secret Manager access for GKE workloads
resource "google_project_iam_member" "gke_workload_secrets" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Artifact Registry Reader for pulling images
resource "google_project_iam_member" "gke_workload_artifact_registry" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Monitoring Writer for sending metrics
resource "google_project_iam_member" "gke_workload_monitoring" {
  project = local.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Logging Writer for sending logs
resource "google_project_iam_member" "gke_workload_logging" {
  project = local.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Trace Writer for distributed tracing
resource "google_project_iam_member" "gke_workload_trace" {
  project = local.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# -----------------------------------------------------------------------------
# Workload Identity Bindings
# -----------------------------------------------------------------------------

# Bind Kubernetes service accounts to GCP service account
resource "google_service_account_iam_binding" "gke_workload_identity" {
  service_account_id = google_service_account.gke_workload.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${local.project_id}.svc.id.goog[${local.k8s_namespace}/${local.services.api_core}]",
    "serviceAccount:${local.project_id}.svc.id.goog[${local.k8s_namespace}/${local.services.api_usage}]",
    "serviceAccount:${local.project_id}.svc.id.goog[${local.k8s_namespace}/${local.services.api_message}]",
  ]

  # GKE cluster must be created first to establish the workload identity pool
  depends_on = [google_container_cluster.main]
}

# -----------------------------------------------------------------------------
# Redis Service Account Permissions
# -----------------------------------------------------------------------------

# Minimal permissions for Redis VMs
resource "google_project_iam_member" "redis_logging" {
  project = local.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.redis.email}"
}

resource "google_project_iam_member" "redis_monitoring" {
  project = local.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.redis.email}"
}
