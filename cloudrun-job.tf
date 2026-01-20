# =============================================================================
# Cloud Run Job for Batch Processing
# =============================================================================

resource "google_cloud_run_v2_job" "batch_core" {
  name                = "${var.project_name}-batch-core"
  project             = local.project_id
  location            = local.region
  deletion_protection = false

  template {
    parallelism = 1
    task_count  = 1

    template {
      service_account = google_service_account.batch.email
      timeout         = var.batch_timeout
      max_retries     = 1

      # CloudSQL Proxy volume
      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }

      containers {
        image = "${local.artifact_registry_url}/batch-core:latest"

        # Environment variables
        env {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        }

        env {
          name  = "POSTGRES_HOST"
          value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
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

        # Mount CloudSQL proxy socket
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

      # VPC access for internal resources
      vpc_access {
        connector = google_vpc_access_connector.serverless.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
    ]
  }
}
