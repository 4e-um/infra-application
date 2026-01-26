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

# Cloud Scheduler Admin (for fn-batch-control to manage schedules)
resource "google_project_iam_member" "app_scheduler_admin" {
  project = local.project_id
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Cloud Tasks Enqueuer (for fn-batch-control and Scheduler to create tasks)
resource "google_project_iam_member" "app_cloudtasks_enqueuer" {
  project = local.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Cloud Run Developer (for Cloud Tasks to execute jobs)
resource "google_project_iam_member" "app_run_developer" {
  project = local.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# -----------------------------------------------------------------------------
# Cloud Tasks Service Agent Permissions
# -----------------------------------------------------------------------------
# Cloud Tasks service agent needs to generate OIDC tokens for app SA
# to invoke Cloud Run Job on behalf of the queue
resource "google_service_account_iam_member" "cloudtasks_token_creator" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${local.project_number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"
}

# -----------------------------------------------------------------------------
# App SA Self-Impersonation for Cloud Tasks
# -----------------------------------------------------------------------------
# When creating Cloud Tasks with OIDC token targeting app SA,
# the caller (app SA) needs "actAs" permission on itself
resource "google_service_account_iam_member" "app_self_act_as" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.app.email}"
}

# -----------------------------------------------------------------------------
# Cloud Run Job Execution Permissions
# -----------------------------------------------------------------------------
# App SA가 Cloud Run Job 실행 및 상태 조회 가능 (run.developer에 포함)
# fn-batch-control에서 직접 Job 실행 및 상태 확인
