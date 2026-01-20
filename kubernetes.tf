# =============================================================================
# Kubernetes Resources
# =============================================================================
# GKE 클러스터 생성 후 자동으로 K8s 리소스 배포
# - Namespace
# - Secrets (Terraform outputs 사용)
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
# Secrets
# -----------------------------------------------------------------------------

# Database Credentials
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    username        = google_sql_user.main.name
    password        = var.database_password
    database        = google_sql_database.main.name
    connection-name = google_sql_database_instance.main.connection_name
  }

  type = "Opaque"
}

# Redis Usage Credentials
resource "kubernetes_secret" "redis_usage_credentials" {
  metadata {
    name      = "redis-usage-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    endpoint = "${module.redis_usage.private_ip}:6379"
    password = var.redis_usage_password
  }

  type = "Opaque"
}

# Redis Message Credentials
resource "kubernetes_secret" "redis_message_credentials" {
  metadata {
    name      = "redis-message-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    endpoint = "${module.redis_message.private_ip}:6379"
    password = var.redis_message_password
  }

  type = "Opaque"
}

# Kafka Credentials (Confluent Cloud)
resource "kubernetes_secret" "kafka_credentials" {
  metadata {
    name      = "kafka-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    bootstrap-servers = var.kafka_bootstrap_servers
    api-key           = var.kafka_api_key
    api-secret        = var.kafka_api_secret
  }

  type = "Opaque"
}

# Application Secrets
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    aes-secret-key = var.aes_secret_key
  }

  type = "Opaque"
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
      "kubernetes.io/ingress.class"                 = "gce"
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
# Note: BackendConfig is a GKE CRD, using kubernetes_manifest
# This configures health checks for the GCE Ingress Controller

resource "kubernetes_manifest" "backend_config" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "api-backend-config"
      namespace = kubernetes_namespace.app.metadata[0].name
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
  }

  depends_on = [kubernetes_namespace.app]
}
