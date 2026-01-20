# =============================================================================
# GitHub Actions Workload Identity Federation
# =============================================================================
# Enables GitHub Actions to authenticate to GCP without service account keys
# This is OPTIONAL - only created when github_org and github_repos are set
# =============================================================================

# -----------------------------------------------------------------------------
# Workload Identity Pool
# -----------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  count = local.github_enabled ? 1 : 0

  project                   = local.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions CI/CD"
}

# -----------------------------------------------------------------------------
# Workload Identity Provider
# -----------------------------------------------------------------------------

resource "google_iam_workload_identity_pool_provider" "github" {
  count = local.github_enabled ? 1 : 0

  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  attribute_condition = "assertion.repository_owner == '${var.github_org}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# -----------------------------------------------------------------------------
# Service Account for GitHub Actions
# -----------------------------------------------------------------------------

resource "google_service_account" "github_actions" {
  count = local.github_enabled ? 1 : 0

  account_id   = "${var.project_name}-github-actions"
  project      = local.project_id
  display_name = "GitHub Actions SA"
  description  = "Service account for GitHub Actions CI/CD pipelines"
}

# -----------------------------------------------------------------------------
# IAM: GitHub Actions SA Permissions
# -----------------------------------------------------------------------------

# Artifact Registry Writer (push images)
resource "google_project_iam_member" "github_actions_artifact_registry" {
  count = local.github_enabled ? 1 : 0

  project = local.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# GKE Developer (deploy to cluster)
resource "google_project_iam_member" "github_actions_gke" {
  count = local.github_enabled ? 1 : 0

  project = local.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# Storage Object Viewer (for GKE credentials)
resource "google_project_iam_member" "github_actions_storage" {
  count = local.github_enabled ? 1 : 0

  project = local.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# -----------------------------------------------------------------------------
# Workload Identity Binding
# -----------------------------------------------------------------------------

resource "google_service_account_iam_binding" "github_actions_wif" {
  count = local.github_enabled ? 1 : 0

  service_account_id = google_service_account.github_actions[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    for repo in var.github_repos :
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_org}/${repo}"
  ]
}
