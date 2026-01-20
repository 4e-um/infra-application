terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Terraform Cloud/Scalr backend
  # Set organization via CLI or env: TF_CLOUD_ORGANIZATION
  cloud {
    workspaces {
      name = "telecom-app-dev"
    }
  }

  # Alternative: GCS backend (uncomment if not using Terraform Cloud)
  # backend "gcs" {
  #   bucket = "PROJECT_ID-terraform-state"
  #   prefix = "infra-application/dev"
  # }
}

# Note: project and region are read from bootstrap via data.terraform_remote_state
# Provider configuration happens before data sources, so we use a placeholder
# and rely on the actual resources using local.project_id and local.region

provider "google" {
  # Project and region will be set per-resource using local values from bootstrap
  # Or set via environment variables: GOOGLE_PROJECT, GOOGLE_REGION

  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

provider "google-beta" {
  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# =============================================================================
# Kubernetes Provider (authenticated via GKE)
# =============================================================================

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.main.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
}
