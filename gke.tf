# =============================================================================
# GKE AutoPilot Cluster
# =============================================================================

resource "google_container_cluster" "main" {
  name             = "${var.project_name}-cluster"
  project          = local.project_id
  location         = local.region
  enable_autopilot = true

  network    = local.vpc_name
  subnetwork = local.main_subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Public cluster - nodes have external IPs (no NAT needed)
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  workload_identity_config {
    workload_pool = local.workload_identity_pool
  }

  release_channel {
    channel = "REGULAR"
  }

  # Autopilot manages most settings, but we can configure some
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke_workload.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  # Enable GKE Dataplane V2 (built-in with Autopilot)
  datapath_provider = "ADVANCED_DATAPATH"

  # Enable vertical pod autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }

  # Secret Manager addon for CSI Driver
  secret_manager_config {
    enabled = true
  }

  # Security configurations
  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  deletion_protection = false

  depends_on = [
    google_service_account.gke_workload
  ]
}
