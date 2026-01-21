# =============================================================================
# Redis Instances
# =============================================================================

# Redis for api-usage service (real-time usage caching)
module "redis_usage" {
  source = "./modules/redis"

  name                  = "usage"
  project_name          = var.project_name
  project_id            = local.project_id
  zone                  = local.zone
  subnetwork            = local.main_subnet_self_link
  redis_password        = var.redis_usage_password
  service_account_email = google_service_account.app.email
  machine_type          = var.redis_machine_type

  labels = local.common_labels
}

# Redis for api-message service (general caching)
module "redis_message" {
  source = "./modules/redis"

  name                  = "message"
  project_name          = var.project_name
  project_id            = local.project_id
  zone                  = local.zone
  subnetwork            = local.main_subnet_self_link
  redis_password        = var.redis_message_password
  service_account_email = google_service_account.app.email
  machine_type          = var.redis_machine_type

  labels = local.common_labels
}
