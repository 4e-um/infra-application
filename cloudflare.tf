# =============================================================================
# Cloudflare DNS Records
# =============================================================================

# =============================================================================
# Cloud Run Domain Mapping
# =============================================================================
# Cloud Run에서 커스텀 도메인을 사용하려면 Domain Mapping 필요

resource "google_cloud_run_domain_mapping" "api" {
  project  = local.project_id
  location = local.region
  name     = "api.${var.domain_name}"

  metadata {
    namespace = local.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.api_core.name
  }
}

# =============================================================================
# Cloudflare DNS Records
# =============================================================================
# Cloud Run Domain Mapping이 제공하는 레코드를 Cloudflare에 설정

resource "cloudflare_dns_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "CNAME"
  content = "ghs.googlehosted.com"  # Cloud Run domain mapping target
  ttl     = 300
  proxied = false  # DNS only - Cloud Run handles SSL

  comment = "API endpoint - Cloud Run Domain Mapping (managed by Terraform)"
}
