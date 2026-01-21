# =============================================================================
# GKE Standard Cluster (Zonal - Dev Environment)
# =============================================================================

resource "google_container_cluster" "main" {
  name     = "${var.project_name}-cluster"
  project  = local.project_id
  location = local.zone # Zonal cluster (single zone for dev)

  # We can't create a cluster with no node pool, so we create the smallest
  # possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = local.vpc_name
  subnetwork = local.main_subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Public cluster
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

  # Secret Manager addon for CSI Driver
  secret_manager_config {
    enabled = true
  }

  deletion_protection = false

  depends_on = [
    google_service_account.gke_workload
  ]
}

# =============================================================================
# Node Pool (Minimal for Dev)
# =============================================================================

resource "google_container_node_pool" "main" {
  name     = "${var.project_name}-pool"
  project  = local.project_id
  location = local.zone
  cluster  = google_container_cluster.main.name

  node_count = 1 # Single node for dev

  node_config {
    machine_type    = "e2-medium" # 2 vCPU, 4GB RAM - sufficient for dev
    service_account = google_service_account.gke_workload.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Spot VMs for cost savings (dev only)
    spot = true

    labels = local.common_labels

    tags = ["gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
