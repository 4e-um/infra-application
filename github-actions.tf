# =============================================================================
# GitHub Actions Workload Identity Federation
# =============================================================================
# Enables GitHub Actions to authenticate to GCP without service account keys
# This is OPTIONAL - only created when github_org and github_repos are set
# =============================================================================

# -----------------------------------------------------------------------------
# Import: 기존 리소스가 있으면 생성하지 않고 import
# -----------------------------------------------------------------------------
# GCP에 이미 존재하는 Workload Identity Pool/Provider를 Terraform state로 가져옴
# - 리소스가 존재하면: state로 import 후 Terraform이 관리
# - 리소스가 없으면: import 블록 제거 후 새로 생성
#
# 성공적으로 import 완료 후 이 블록들을 삭제하세요.
# soft-delete 상태인 경우: gcloud iam workload-identity-pools undelete 먼저 실행
# -----------------------------------------------------------------------------

import {
  to = google_iam_workload_identity_pool.github[0]
  id = "projects/telecom-app-dev/locations/global/workloadIdentityPools/github-actions-pool"
}

import {
  to = google_iam_workload_identity_pool_provider.github[0]
  id = "projects/telecom-app-dev/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"
}

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

# Cloud Run Developer (deploy Cloud Run services and jobs)
resource "google_project_iam_member" "github_actions_run" {
  count = local.github_enabled ? 1 : 0

  project = local.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# Act as App SA (required to update Cloud Run Job)
resource "google_service_account_iam_member" "github_actions_act_as_app" {
  count = local.github_enabled ? 1 : 0

  service_account_id = google_service_account.app.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions[0].email}"
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
