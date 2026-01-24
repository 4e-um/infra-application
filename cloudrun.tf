# =============================================================================
# Cloud Run Services
# =============================================================================
# 3개의 Cloud Run 서비스: api-core (공개), api-usage (내부), api-message (내부)
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
# api-usage: Kafka consume/produce 서비스 (공개)
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
# api-message: Kafka consumer 서비스 (내부 전용)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "api_message" {
  name                = "${var.project_name}-api-message"
  project             = local.project_id
  location            = local.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"

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
