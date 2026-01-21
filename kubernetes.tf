# =============================================================================
# Kubernetes Resources
# =============================================================================
# NOTE: K8s resources are managed by CI/CD (kubectl apply), not Terraform
#
# Reason: Kubernetes provider requires cluster connection at plan time,
# but cluster doesn't exist during initial terraform apply.
#
# K8s manifests location:
#   - Namespace:          -backends/api-*/k8s/namespace.yaml
#   - ServiceAccount:     -backends/api-*/k8s/serviceaccount.yaml
#   - SecretProviderClass: -backends/api-*/k8s/secret-provider-class.yaml
#   - Deployment:         -backends/api-*/k8s/deployment.yaml
#   - Service:            -backends/api-*/k8s/service.yaml
#   - HPA:                -backends/api-*/k8s/hpa.yaml
#   - Ingress:            -backends/api-*/k8s/ingress.yaml (TODO: create)
#   - BackendConfig:      -backends/api-*/k8s/backend-config.yaml (TODO: create)
# =============================================================================
