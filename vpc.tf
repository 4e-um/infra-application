# =============================================================================
# VPC Access Connector (for Cloud Run)
# =============================================================================

resource "google_vpc_access_connector" "serverless" {
  name    = "${var.project_name}-connector"
  project = local.project_id
  region  = local.region

  subnet {
    name       = local.serverless_subnet_name
    project_id = local.project_id
  }

  min_instances = 2
  max_instances = 3
  machine_type  = "e2-micro"
}

# =============================================================================
# Global Load Balancer IP
# =============================================================================

resource "google_compute_global_address" "lb" {
  name    = "${var.project_name}-lb-ip"
  project = local.project_id
}
