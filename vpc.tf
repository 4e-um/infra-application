# =============================================================================
# Global Load Balancer IP
# =============================================================================

resource "google_compute_global_address" "lb" {
  name    = "${var.project_name}-lb-ip"
  project = local.project_id
}
