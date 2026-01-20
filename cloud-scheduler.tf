# =============================================================================
# Cloud Scheduler Jobs
# =============================================================================

# Invoice Job - Runs monthly on the 1st at 01:00 KST
resource "google_cloud_scheduler_job" "invoice_job" {
  name        = "${var.project_name}-invoice-scheduler"
  project     = local.project_id
  description = "Triggers monthly invoice batch job"
  region      = local.region
  schedule    = "0 1 1 * *" # 1st of every month at 01:00
  time_zone   = "Asia/Seoul"

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "300s"
  }

  http_target {
    http_method = "POST"
    uri         = "https://${local.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${local.project_id}/jobs/${google_cloud_run_v2_job.batch_core.name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      overrides = {
        containerOverrides = [{
          args = [
            "--spring.batch.job.name=invoiceJob",
            "--billingYm=$${date('yyyyMM', time.scheduled_time - duration('720h'))}"
          ]
        }]
      }
    }))
  }
}

# Invoice Item Job - Runs monthly on the 1st at 02:00 KST (after invoice job)
resource "google_cloud_scheduler_job" "invoice_item_job" {
  name        = "${var.project_name}-invoice-item-scheduler"
  project     = local.project_id
  description = "Triggers monthly invoice item batch job"
  region      = local.region
  schedule    = "0 2 1 * *" # 1st of every month at 02:00
  time_zone   = "Asia/Seoul"

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "300s"
  }

  http_target {
    http_method = "POST"
    uri         = "https://${local.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${local.project_id}/jobs/${google_cloud_run_v2_job.batch_core.name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      overrides = {
        containerOverrides = [{
          args = [
            "--spring.batch.job.name=invoiceItemJob",
            "--billingYm=$${date('yyyyMM', time.scheduled_time - duration('720h'))}"
          ]
        }]
      }
    }))
  }
}
