# =============================================================================
# Cloud Function (fn-batch-control) as Cloud Run v2 Service
# =============================================================================
# Gen2 Cloud Functions는 Cloud Run 서비스로 실행됨
# Cloud Scheduler 관리 및 Cloud Run Job 실행을 위한 API 제공

# -----------------------------------------------------------------------------
# Data source for project number
# -----------------------------------------------------------------------------

data "google_project" "current" {
  project_id = local.project_id
}

# -----------------------------------------------------------------------------
# fn-batch-control: Cloud Run Service (공개)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "fn_batch_control" {
  name                = "${var.project_name}-fn-batch-control"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = 0
      max_instance_count = var.fn_batch_control_max_instances
    }

    containers {
      # Placeholder image - CI/CD will update this
      image = "gcr.io/cloudrun/hello"

      # Environment variables
      env {
        name  = "GCP_PROJECT"
        value = local.project_id
      }

      env {
        name  = "GCP_REGION"
        value = local.region
      }

      env {
        name  = "GCP_PROJECT_NUMBER"
        value = data.google_project.current.number
      }

      # Resource limits
      resources {
        limits = {
          cpu    = var.fn_batch_control_cpu_limit
          memory = var.fn_batch_control_memory_limit
        }
        startup_cpu_boost = true
      }

      ports {
        container_port = 8080
      }

      # Startup probe: 함수 시작 대기
      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 3
        period_seconds        = 3
        failure_threshold     = 10
      }
    }

    max_instance_request_concurrency = var.fn_batch_control_concurrency
    timeout                          = "${var.fn_batch_control_timeout}s"
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# fn-batch-control: 공개 접근 허용 (allUsers)
resource "google_cloud_run_v2_service_iam_member" "fn_batch_control_public" {
  project  = local.project_id
  location = local.region
  name     = google_cloud_run_v2_service.fn_batch_control.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
