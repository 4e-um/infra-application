# =============================================================================
# Cloudflare DNS Records
# =============================================================================

# API subdomain DNS record pointing to GCP Load Balancer
resource "cloudflare_dns_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "A"
  content = google_compute_global_address.lb.address
  ttl     = 1    # Automatic TTL (required when proxied)
  proxied = true # Enable Cloudflare proxy for SSL termination

  comment = "API endpoint for ${var.project_name} (managed by Terraform)"
}

# Optional: Additional subdomains if needed
# resource "cloudflare_record" "api_usage" {
#   zone_id = var.cloudflare_zone_id
#   name    = "api-usage"
#   type    = "A"
#   content = google_compute_global_address.lb.address
#   proxied = true
#
#   comment = "API Usage endpoint for ${var.project_name} (managed by Terraform)"
# }
