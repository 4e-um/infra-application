# =============================================================================
# Service Accounts
# =============================================================================

# GKE Workload Identity Service Account
resource "google_service_account" "gke_workload" {
  account_id   = "${var.project_name}-gke-workload"
  project      = local.project_id
  display_name = "GKE Workload Identity SA"
  description  = "Service account for GKE workloads using Workload Identity"
}

# Batch Job Service Account
resource "google_service_account" "batch" {
  account_id   = "${var.project_name}-batch"
  project      = local.project_id
  display_name = "Batch Job SA"
  description  = "Service account for Cloud Run batch jobs"
}

# Cloud Scheduler Service Account
resource "google_service_account" "scheduler" {
  account_id   = "${var.project_name}-scheduler"
  project      = local.project_id
  display_name = "Cloud Scheduler SA"
  description  = "Service account for Cloud Scheduler to invoke Cloud Run jobs"
}

# Redis VM Service Account
resource "google_service_account" "redis" {
  account_id   = "${var.project_name}-redis"
  project      = local.project_id
  display_name = "Redis VM SA"
  description  = "Service account for Redis VM instances"
}
