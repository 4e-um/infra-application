# =============================================================================
# Cloudflare DNS Records
# =============================================================================

# API subdomain DNS record pointing to Cloud Run service
resource "cloudflare_dns_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "CNAME"
  content = trimprefix(google_cloud_run_v2_service.api_core.uri, "https://")
  ttl     = 1    # Automatic TTL (required when proxied)
  proxied = true # Enable Cloudflare proxy for SSL termination

  comment = "API endpoint - Cloud Run (managed by Terraform)"
}
