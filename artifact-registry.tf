# =============================================================================
# Artifact Registry
# =============================================================================

resource "google_artifact_registry_repository" "main" {
  project       = local.project_id
  location      = local.region
  repository_id = "${var.project_name}-repo"
  description   = "Docker repository for ${var.project_name} container images"
  format        = "DOCKER"

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days
    }
  }

  labels = local.common_labels
}
