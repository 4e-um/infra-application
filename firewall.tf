# =============================================================================
# Application-specific Firewall Rules
# =============================================================================
# Note: Basic firewall rules (internal, IAP SSH, health checks) are in bootstrap

# Allow external Redis access (dev only - allow all)
resource "google_compute_firewall" "allow_redis_external" {
  name    = "${var.project_name}-allow-redis-external"
  project = local.project_id
  network = local.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["redis"]

  priority = 1000
}
