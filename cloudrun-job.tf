# =============================================================================
# Cloud Run Job for Batch Processing
# =============================================================================
# 연결 방식: Socket Factory (Cloud Run 내장 CloudSQL 연결)
# - VPC Connector 불필요 (비용 절감)
# - 내부 네트워크 통신 (보안)
# - Spring Boot에서 postgres-socket-factory 의존성 필요

resource "google_cloud_run_v2_job" "batch_core" {
  name                = "${var.project_name}-batch-core"
  project             = local.project_id
  location            = local.region
  deletion_protection = false

  template {
    parallelism = 1
    task_count  = 1

    template {
      service_account = google_service_account.app.email
      timeout         = var.batch_timeout
      max_retries     = 1

      containers {
        # Placeholder image for initial deployment - CI/CD will update this
        image = "gcr.io/cloudrun/hello"

        # Environment variables
        # 프로필 조합: dev(환경) + cloudrun(DB연결방식)
        env {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "${var.environment},cloudrun"
        }

        # Database connection via Socket Factory
        # Spring Boot JDBC URL: jdbc:postgresql:///${POSTGRES_DATABASE}?cloudSqlInstance=${DB_INSTANCE_CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory
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

        # CloudSQL Socket mount (Cloud Run이 자동으로 소켓 생성)
        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }

        # Resource limits
        resources {
          limits = {
            cpu    = var.batch_cpu_limit
            memory = var.batch_memory_limit
          }
        }
      }

      # CloudSQL 연결 볼륨
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }

    }
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_iam_member.app_secrets,
    google_project_iam_member.app_cloudsql,
  ]
}
