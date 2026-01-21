# =============================================================================
# Service Account (Unified for Dev)
# =============================================================================
# Single SA for all workloads: GKE, Cloud Run, Scheduler, Redis VMs

resource "google_service_account" "app" {
  account_id   = "${var.project_name}-app"
  project      = local.project_id
  display_name = "App Service Account"
  description  = "Unified service account for all application workloads (dev)"
}
