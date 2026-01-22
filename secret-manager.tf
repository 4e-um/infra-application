# =============================================================================
# Secret Manager Secrets
# =============================================================================

# -----------------------------------------------------------------------------
# Database Credentials
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "db_user" {
  project   = local.project_id
  secret_id = "${var.project_name}-db-user"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "db_user" {
  secret      = google_secret_manager_secret.db_user.id
  secret_data = google_sql_user.main.name
}

resource "google_secret_manager_secret" "db_password" {
  project   = local.project_id
  secret_id = "${var.project_name}-db-password"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.database_password
}

resource "google_secret_manager_secret" "db_connection_name" {
  project   = local.project_id
  secret_id = "${var.project_name}-db-connection-name"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "db_connection_name" {
  secret      = google_secret_manager_secret.db_connection_name.id
  secret_data = google_sql_database_instance.main.connection_name
}

# -----------------------------------------------------------------------------
# Kafka Credentials (Individual secrets for Spring Boot env vars)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "kafka_bootstrap_servers" {
  project   = local.project_id
  secret_id = "${var.project_name}-kafka-bootstrap-servers"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "kafka_bootstrap_servers" {
  secret      = google_secret_manager_secret.kafka_bootstrap_servers.id
  secret_data = var.kafka_bootstrap_servers
}

resource "google_secret_manager_secret" "kafka_api_key" {
  project   = local.project_id
  secret_id = "${var.project_name}-kafka-api-key"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "kafka_api_key" {
  secret      = google_secret_manager_secret.kafka_api_key.id
  secret_data = var.kafka_api_key
}

resource "google_secret_manager_secret" "kafka_api_secret" {
  project   = local.project_id
  secret_id = "${var.project_name}-kafka-api-secret"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "kafka_api_secret" {
  secret      = google_secret_manager_secret.kafka_api_secret.id
  secret_data = var.kafka_api_secret
}

# -----------------------------------------------------------------------------
# Redis Credentials
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "redis_usage" {
  project   = local.project_id
  secret_id = "${var.project_name}-redis-usage-password"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "redis_usage" {
  secret      = google_secret_manager_secret.redis_usage.id
  secret_data = var.redis_usage_password
}

resource "google_secret_manager_secret" "redis_message" {
  project   = local.project_id
  secret_id = "${var.project_name}-redis-message-password"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "redis_message" {
  secret      = google_secret_manager_secret.redis_message.id
  secret_data = var.redis_message_password
}

# Redis endpoints (Experimental: using external IP for Cloud Run access)
resource "google_secret_manager_secret" "redis_usage_endpoint" {
  project   = local.project_id
  secret_id = "${var.project_name}-redis-usage-endpoint"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "redis_usage_endpoint" {
  secret      = google_secret_manager_secret.redis_usage_endpoint.id
  secret_data = "${module.redis_usage.external_ip}:6379" # Experimental: external IP
}

resource "google_secret_manager_secret" "redis_message_endpoint" {
  project   = local.project_id
  secret_id = "${var.project_name}-redis-message-endpoint"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "redis_message_endpoint" {
  secret      = google_secret_manager_secret.redis_message_endpoint.id
  secret_data = "${module.redis_message.external_ip}:6379" # Experimental: external IP
}

# -----------------------------------------------------------------------------
# Application Secrets
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "aes_secret_key" {
  count     = var.aes_secret_key != "" ? 1 : 0
  project   = local.project_id
  secret_id = "${var.project_name}-aes-secret-key"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "aes_secret_key" {
  count       = var.aes_secret_key != "" ? 1 : 0
  secret      = google_secret_manager_secret.aes_secret_key[0].id
  secret_data = var.aes_secret_key
}

# -----------------------------------------------------------------------------
# Ureca Secrets (api-core)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "ureca_secret_key" {
  project   = local.project_id
  secret_id = "${var.project_name}-ureca-secret-key"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "ureca_secret_key" {
  secret      = google_secret_manager_secret.ureca_secret_key.id
  secret_data = var.ureca_secret_key
}

resource "google_secret_manager_secret" "ureca_hash_key" {
  project   = local.project_id
  secret_id = "${var.project_name}-ureca-hash-key"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "ureca_hash_key" {
  secret      = google_secret_manager_secret.ureca_hash_key.id
  secret_data = var.ureca_hash_key
}
