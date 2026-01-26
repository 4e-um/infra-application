# =============================================================================
# Cloud Tasks Queue for Batch Job Serialization
# =============================================================================
# 목적: Cloud Run Job 실행을 직렬화하여 동시 실행 충돌 방지
# 호출자: Scheduler, Cloud Function (fn-batch-control)
# 타겟: fn-batch-control /internal/execute
#
# 플로우:
# 1. Cloud Tasks → fn-batch-control/internal/execute
# 2. Job 실행 중? → 503 반환 → Cloud Tasks 재시도 (30초 후)
# 3. Job 미실행? → Job 직접 실행 → 200 반환 → Task 완료

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
