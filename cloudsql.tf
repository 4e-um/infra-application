# =============================================================================
# CloudSQL PostgreSQL Instance (Experimental - Simplified)
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

  settings {
    tier              = var.database_tier
    availability_type = "ZONAL"
    disk_size         = var.database_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = false # Experimental: fixed size

    ip_configuration {
      ipv4_enabled = true # Experimental: Public IP only

      # Experimental: allow all IPs (for debugging convenience)
      authorized_networks {
        name  = "allow-all-experimental"
        value = "0.0.0.0/0"
      }
    }

    # Experimental: disable backups
    backup_configuration {
      enabled                        = false
      point_in_time_recovery_enabled = false
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 4 # 04:00 UTC (13:00 KST)
      update_track = "stable"
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

  depends_on = [google_sql_user.main]
}

resource "google_sql_user" "main" {
  name     = "app_user"
  project  = local.project_id
  instance = google_sql_database_instance.main.name
  password = var.database_password
}
