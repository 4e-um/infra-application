# =============================================================================
# CloudSQL PostgreSQL Instance
# =============================================================================

resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "main" {
  name                = "${var.project_name}-postgres-${random_id.db_suffix.hex}"
  project             = local.project_id
  database_version    = "POSTGRES_15"
  region              = local.region
  deletion_protection = false

  # Private Service Access is configured in bootstrap
  # VPC peering should already exist

  settings {
    tier              = var.database_tier
    availability_type = "ZONAL"
    disk_size         = var.database_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled                                  = true  # Enable for dev access
      private_network                               = local.vpc_self_link
      enable_private_path_for_google_cloud_services = true

      # Allow access from anywhere (dev only - restrict in prod)
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 4 # 04:00 UTC (13:00 KST)
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }
  }
}

# =============================================================================
# Database and User
# =============================================================================

resource "google_sql_database" "main" {
  name     = "app_db"
  project  = local.project_id
  instance = google_sql_database_instance.main.name

  # user보다 먼저 삭제되도록 설정 (삭제 시 역순 적용)
  # app_user가 소유한 객체들이 database와 함께 삭제되어야 user 삭제 가능
  depends_on = [google_sql_user.main]
}

resource "google_sql_user" "main" {
  name     = "app_user"
  project  = local.project_id
  instance = google_sql_database_instance.main.name
  password = var.database_password
}
