# =============================================================================
# Cloud Tasks Queue for Batch Job Serialization
# =============================================================================
# 목적: Cloud Run Job 실행을 직렬화하여 동시 실행 충돌 방지
# 호출자: Scheduler, Cloud Function (fn-batch-control)
# 타겟: Cloud Run Job (batch-core)

resource "google_cloud_tasks_queue" "batch_queue" {
  name     = "${var.project_name}-batch-queue"
  project  = local.project_id
  location = local.region

  rate_limits {
    max_concurrent_dispatches = 1 # 동시 실행 1개로 제한 (직렬화)
    max_dispatches_per_second = 1 # 초당 최대 1개 디스패치
  }

  retry_config {
    max_attempts       = var.batch_queue_max_attempts      # default: 3
    min_backoff        = "${var.batch_queue_min_backoff}s" # default: 10s
    max_backoff        = "${var.batch_queue_max_backoff}s" # default: 300s
    max_doublings      = 4
    max_retry_duration = "${var.batch_queue_max_retry_duration}s" # default: 0 (unlimited)
  }

  stackdriver_logging_config {
    sampling_ratio = 1.0 # 모든 로그 기록
  }
}
