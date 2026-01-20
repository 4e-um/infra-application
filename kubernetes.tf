# =============================================================================
# Kubernetes Resources
# =============================================================================
# GKE 클러스터 생성 후 자동으로 K8s 리소스 배포
# - Namespace
# - SecretProviderClass (Secret Manager CSI Driver)
# - Service Accounts (Workload Identity)
# - Ingress + BackendConfig
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "app" {
  metadata {
    name = local.k8s_namespace

    labels = {
      name        = local.k8s_namespace
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  depends_on = [google_container_cluster.main]
}

# -----------------------------------------------------------------------------
# SecretProviderClass (Secret Manager CSI Driver)
# -----------------------------------------------------------------------------
# Pod에서 Secret Manager의 비밀을 파일로 마운트
# kubectl provider 사용 (plan 단계에서 API 연결 안함)

# api-core용 SecretProviderClass
resource "kubectl_manifest" "secret_provider_api_core" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "api-core-secrets"
      namespace = local.k8s_namespace
    }
    spec = {
      provider = "gcp"
      parameters = {
        secrets = yamlencode([
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-user/versions/latest"
            path         = "db-username"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-password/versions/latest"
            path         = "db-password"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-connection-name/versions/latest"
            path         = "db-connection-name"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-kafka-credentials/versions/latest"
            path         = "kafka-credentials"
          }
        ])
      }
    }
  })

  depends_on = [
    kubernetes_namespace.app,
    google_secret_manager_secret_version.db_user,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.db_connection_name,
    google_secret_manager_secret_version.kafka
  ]
}

# api-usage용 SecretProviderClass
resource "kubectl_manifest" "secret_provider_api_usage" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "api-usage-secrets"
      namespace = local.k8s_namespace
    }
    spec = {
      provider = "gcp"
      parameters = {
        secrets = yamlencode([
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-user/versions/latest"
            path         = "db-username"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-password/versions/latest"
            path         = "db-password"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-connection-name/versions/latest"
            path         = "db-connection-name"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-redis-usage-endpoint/versions/latest"
            path         = "redis-endpoint"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-redis-usage-password/versions/latest"
            path         = "redis-password"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-kafka-credentials/versions/latest"
            path         = "kafka-credentials"
          }
        ])
      }
    }
  })

  depends_on = [
    kubernetes_namespace.app,
    google_secret_manager_secret_version.db_user,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.db_connection_name,
    google_secret_manager_secret_version.redis_usage,
    google_secret_manager_secret_version.redis_usage_endpoint,
    google_secret_manager_secret_version.kafka
  ]
}

# api-message용 SecretProviderClass
resource "kubectl_manifest" "secret_provider_api_message" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "api-message-secrets"
      namespace = local.k8s_namespace
    }
    spec = {
      provider = "gcp"
      parameters = {
        secrets = yamlencode(concat([
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-user/versions/latest"
            path         = "db-username"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-password/versions/latest"
            path         = "db-password"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-db-connection-name/versions/latest"
            path         = "db-connection-name"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-redis-message-endpoint/versions/latest"
            path         = "redis-endpoint"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-redis-message-password/versions/latest"
            path         = "redis-password"
          },
          {
            resourceName = "projects/${local.project_id}/secrets/${var.project_name}-kafka-credentials/versions/latest"
            path         = "kafka-credentials"
          }
        ],
        var.aes_secret_key != "" ? [{
          resourceName = "projects/${local.project_id}/secrets/${var.project_name}-aes-secret-key/versions/latest"
          path         = "aes-secret-key"
        }] : []))
      }
    }
  })

  depends_on = [
    kubernetes_namespace.app,
    google_secret_manager_secret_version.db_user,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.db_connection_name,
    google_secret_manager_secret_version.redis_message,
    google_secret_manager_secret_version.redis_message_endpoint,
    google_secret_manager_secret_version.kafka
  ]
}

# -----------------------------------------------------------------------------
# Service Accounts (Workload Identity)
# -----------------------------------------------------------------------------

resource "kubernetes_service_account" "api_core" {
  metadata {
    name      = local.services.api_core
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gke_workload.email
    }
  }
}

resource "kubernetes_service_account" "api_usage" {
  metadata {
    name      = local.services.api_usage
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gke_workload.email
    }
  }
}

resource "kubernetes_service_account" "api_message" {
  metadata {
    name      = local.services.api_message
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gke_workload.email
    }
  }
}

# -----------------------------------------------------------------------------
# Ingress
# -----------------------------------------------------------------------------

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name      = "api-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "kubernetes.io/ingress.class"                  = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.lb.name
      "kubernetes.io/ingress.allow-http"            = "true"
    }
  }

  spec {
    rule {
      http {
        # api-core routes
        path {
          path      = "/api/v1/core/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.services.api_core
              port {
                number = 80
              }
            }
          }
        }

        # api-usage routes
        path {
          path      = "/api/v1/usage/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.services.api_usage
              port {
                number = 80
              }
            }
          }
        }

        # api-message routes
        path {
          path      = "/api/v1/message/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.services.api_message
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/api/v1/notification/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.services.api_message
              port {
                number = 80
              }
            }
          }
        }

        # Health check / default route
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = local.services.api_core
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.app,
    google_compute_global_address.lb
  ]
}

# -----------------------------------------------------------------------------
# Backend Config (GKE-specific CRD)
# -----------------------------------------------------------------------------
# kubectl provider 사용 (plan 단계에서 API 연결 안함)

resource "kubectl_manifest" "backend_config" {
  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "api-backend-config"
      namespace = local.k8s_namespace
    }
    spec = {
      healthCheck = {
        checkIntervalSec   = 30
        timeoutSec         = 10
        healthyThreshold   = 1
        unhealthyThreshold = 3
        type               = "HTTP"
        requestPath        = "/actuator/health"
        port               = 8080
      }
      connectionDraining = {
        drainingTimeoutSec = 30
      }
    }
  })

  depends_on = [kubernetes_namespace.app]
}
