# =============================================================================
# Cloudflare Worker Reverse Proxy for Cloud Run
# =============================================================================
# asia-northeast3 리전은 Cloud Run Domain Mapping 미지원
# Cloudflare Worker를 통해 커스텀 도메인 → Cloud Run 프록시
#
# 장점:
# - 거의 무료 (100k 요청/일 Free Tier)
# - Cloudflare WAF, DDoS, 캐싱 사용 가능
# - Google LB 불필요 (월 ~$18 절감)
# =============================================================================

# -----------------------------------------------------------------------------
# Worker Script: Cloud Run Reverse Proxy
# -----------------------------------------------------------------------------

resource "cloudflare_worker_script" "api_proxy" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-api-proxy"
  content    = <<-EOF
    export default {
      async fetch(request, env) {
        const url = new URL(request.url);

        // Cloud Run 서비스 URL로 변경
        url.hostname = env.CLOUD_RUN_HOST;
        url.protocol = "https:";

        // 원본 요청을 Cloud Run으로 프록시
        const response = await fetch(url.toString(), {
          method: request.method,
          headers: request.headers,
          body: request.body,
          redirect: "follow"
        });

        // 응답 반환 (CORS 헤더 추가 가능)
        return response;
      }
    }
  EOF

  # Cloud Run 호스트를 환경변수로 주입
  plain_text_binding {
    name = "CLOUD_RUN_HOST"
    text = trimprefix(trimprefix(google_cloud_run_v2_service.api_core.uri, "https://"), "http://")
  }
}

# -----------------------------------------------------------------------------
# Worker Route: api.domain.com/* → Worker
# -----------------------------------------------------------------------------

resource "cloudflare_worker_route" "api" {
  zone_id     = var.cloudflare_zone_id
  pattern     = "api.${var.domain_name}/*"
  script_name = cloudflare_worker_script.api_proxy.name
}

# -----------------------------------------------------------------------------
# DNS Record: api → Cloudflare Proxy (Worker가 처리)
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "A"
  content = "192.0.2.1"  # Dummy IP - Worker가 실제 라우팅 처리
  ttl     = 1            # Auto TTL (proxied 모드)
  proxied = true         # Cloudflare Proxy ON - Worker로 라우팅

  comment = "API endpoint - Cloudflare Worker proxy to Cloud Run (managed by Terraform)"
}
