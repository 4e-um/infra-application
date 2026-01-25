# =============================================================================
# Cloud Run Services
# =============================================================================
# 3개의 Cloud Run 서비스: api-core, api-usage, api-message (모두 외부 접근 허용)
# 연결 방식: Socket Factory (Cloud Run 내장 CloudSQL 연결)
# - VPC Connector 불필요 (비용 절감)
# - Spring Boot에서 postgres-socket-factory 의존성 필요

# -----------------------------------------------------------------------------
# api-core: 외부 HTTP API (공개)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "api_core" {
  name                = "${var.project_name}-api-core"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = var.api_max_instances
    }

    # 시작 시 CPU 부스트 (Cold Start 개선)
    containers {
      # Placeholder image - CI/CD will update this
      image = "gcr.io/cloudrun/hello"

      # Environment variables
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "${var.environment},cloudrun"
      }

      # Database connection via Socket Factory
      env {
        name  = "DB_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.main.connection_name
      }

      env {
        name  = "POSTGRES_DATABASE"
        value = google_sql_database.main.name
      }

      env {
        name = "POSTGRES_USER"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      # Kafka credentials (individual env vars for Spring Boot)
      env {
        name = "KAFKA_BOOTSTRAP_SERVERS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_bootstrap_servers.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_secret.secret_id
            version = "latest"
          }
        }
      }

      # Ureca secrets (api-core specific)
      env {
        name = "URECA_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ureca_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "URECA_HASH_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ureca_hash_key.secret_id
            version = "latest"
          }
        }
      }

      # OpenTelemetry Configuration
      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = var.otel_exporter_endpoint
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_SERVICE_NAME"
          value = "api-core"
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_ENVIRONMENT"
          value = var.environment
        }
      }

      # CloudSQL Socket mount
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Resource limits
      resources {
        limits = {
          cpu    = var.api_cpu_limit
          memory = var.api_memory_limit
        }
      }

      ports {
        container_port = 8080
      }

      # Startup probe: Spring Boot 시작 대기 (최대 300초)
      startup_probe {
        http_get {
          path = "/actuator/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      # Liveness probe: 앱 정상 동작 확인
      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    # CloudSQL 연결 볼륨
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    max_instance_request_concurrency = var.api_concurrency
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.app_secrets,
    google_project_iam_member.app_cloudsql,
  ]
}

# api-core: 공개 접근 허용 (allUsers)
resource "google_cloud_run_v2_service_iam_member" "api_core_public" {
  project  = local.project_id
  location = local.region
  name     = google_cloud_run_v2_service.api_core.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -----------------------------------------------------------------------------
# api-usage: Kafka consume/produce 서비스 (외부 접근 허용)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "api_usage" {
  name                = "${var.project_name}-api-usage"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = 5
    }

    containers {
      # Placeholder image - CI/CD will update this
      image = "gcr.io/cloudrun/hello"

      # Environment variables
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "${var.environment},cloudrun"
      }

      # Database connection via Socket Factory
      env {
        name  = "DB_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.main.connection_name
      }

      env {
        name  = "POSTGRES_DATABASE"
        value = google_sql_database.main.name
      }

      env {
        name = "POSTGRES_USER"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      # Redis credentials (external IP)
      env {
        name = "REDIS_ENDPOINT"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_usage_endpoint.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "REDIS_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_usage.secret_id
            version = "latest"
          }
        }
      }

      # Kafka credentials (individual env vars for Spring Boot)
      env {
        name = "KAFKA_BOOTSTRAP_SERVERS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_bootstrap_servers.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_secret.secret_id
            version = "latest"
          }
        }
      }

      # OpenTelemetry Configuration
      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = var.otel_exporter_endpoint
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_SERVICE_NAME"
          value = "api-usage"
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_ENVIRONMENT"
          value = var.environment
        }
      }

      # CloudSQL Socket mount
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Resource limits
      resources {
        limits = {
          cpu    = var.api_cpu_limit
          memory = var.api_memory_limit
        }
      }

      ports {
        container_port = 8080
      }

      # Startup probe: Spring Boot 시작 대기 (최대 300초)
      startup_probe {
        http_get {
          path = "/actuator/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      # Liveness probe: 앱 정상 동작 확인
      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    # CloudSQL 연결 볼륨
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    max_instance_request_concurrency = var.api_concurrency
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.app_secrets,
    google_project_iam_member.app_cloudsql,
  ]
}

# api-usage: 공개 접근 허용 (allUsers)
resource "google_cloud_run_v2_service_iam_member" "api_usage_public" {
  project  = local.project_id
  location = local.region
  name     = google_cloud_run_v2_service.api_usage.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -----------------------------------------------------------------------------
# api-message: Kafka consumer 서비스 (외부 접근 허용)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "api_message" {
  name                = "${var.project_name}-api-message"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = 5
    }

    containers {
      # Placeholder image - CI/CD will update this
      image = "gcr.io/cloudrun/hello"

      # Environment variables
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "${var.environment},cloudrun"
      }

      # Database connection via Socket Factory
      env {
        name  = "DB_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.main.connection_name
      }

      env {
        name  = "POSTGRES_DATABASE"
        value = google_sql_database.main.name
      }

      env {
        name = "POSTGRES_USER"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      # Redis credentials (external IP)
      env {
        name = "REDIS_ENDPOINT"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_message_endpoint.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "REDIS_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_message.secret_id
            version = "latest"
          }
        }
      }

      # Kafka credentials (individual env vars for Spring Boot)
      env {
        name = "KAFKA_BOOTSTRAP_SERVERS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_bootstrap_servers.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "KAFKA_API_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.kafka_api_secret.secret_id
            version = "latest"
          }
        }
      }

      # Ureca secrets (same as api-core)
      env {
        name = "URECA_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ureca_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "URECA_HASH_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ureca_hash_key.secret_id
            version = "latest"
          }
        }
      }

      # OpenTelemetry Configuration
      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = var.otel_exporter_endpoint
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_SERVICE_NAME"
          value = "api-message"
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_ENVIRONMENT"
          value = var.environment
        }
      }

      # CloudSQL Socket mount
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Resource limits
      resources {
        limits = {
          cpu    = var.api_cpu_limit
          memory = var.api_memory_limit
        }
      }

      ports {
        container_port = 8080
      }

      # Startup probe: Spring Boot 시작 대기 (최대 300초)
      startup_probe {
        http_get {
          path = "/actuator/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      # Liveness probe: 앱 정상 동작 확인
      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    # CloudSQL 연결 볼륨
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    max_instance_request_concurrency = var.api_concurrency
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.app_secrets,
    google_project_iam_member.app_cloudsql,
  ]
}

# api-message: 공개 접근 허용 (allUsers)
resource "google_cloud_run_v2_service_iam_member" "api_message_public" {
  project  = local.project_id
  location = local.region
  name     = google_cloud_run_v2_service.api_message.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -----------------------------------------------------------------------------
# api-mock: Mock 서비스 (H2 인메모리 DB, 외부 접근 허용)
# -----------------------------------------------------------------------------
# 특징: CloudSQL/Redis/Kafka 연결 불필요, H2 인메모리 DB 사용

resource "google_cloud_run_v2_service" "api_mock" {
  name                = "${var.project_name}-api-mock"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = 3
    }

    containers {
      # Placeholder image - CI/CD will update this
      image = "gcr.io/cloudrun/hello"

      # Environment variables
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "${var.environment},cloudrun"
      }

      # Mock server port (Cloud Run uses 8080)
      env {
        name  = "MOCK_SERVER_PORT"
        value = "8080"
      }

      # H2 console settings for Cloud Run
      env {
        name  = "MOCK_H2_CONSOLE_ENABLED"
        value = "true"
      }

      env {
        name  = "MOCK_H2_ALLOW_OTHERS"
        value = "true"
      }

      # OpenTelemetry Configuration
      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = var.otel_exporter_endpoint
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_SERVICE_NAME"
          value = "api-mock"
        }
      }

      dynamic "env" {
        for_each = var.otel_enabled ? [1] : []
        content {
          name  = "OTEL_ENVIRONMENT"
          value = var.environment
        }
      }

      # Resource limits (lighter than other services)
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      ports {
        container_port = 8080
      }

      # Startup probe: Spring Boot 시작 대기 (최대 300초)
      startup_probe {
        http_get {
          path = "/actuator/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      # Liveness probe: 앱 정상 동작 확인
      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    max_instance_request_concurrency = var.api_concurrency
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.app_secrets,
  ]
}

# api-mock: 공개 접근 허용 (allUsers)
resource "google_cloud_run_v2_service_iam_member" "api_mock_public" {
  project  = local.project_id
  location = local.region
  name     = google_cloud_run_v2_service.api_mock.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
