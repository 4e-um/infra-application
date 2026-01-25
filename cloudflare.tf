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

resource "cloudflare_workers_script" "api_proxy" {
  account_id  = var.cloudflare_account_id
  script_name = "${var.project_name}-api-proxy"

  # ES Module syntax Worker
  content = <<-EOF
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

        // 응답 반환
        return response;
      }
    }
  EOF

  main_module = "worker.js"

  # Cloud Run 호스트를 환경변수로 주입
  bindings = [
    {
      name = "CLOUD_RUN_HOST"
      type = "plain_text"
      text = trimprefix(trimprefix(google_cloud_run_v2_service.api_core.uri, "https://"), "http://")
    }
  ]
}

# -----------------------------------------------------------------------------
# Worker Route: api.domain.com/* → Worker
# -----------------------------------------------------------------------------

resource "cloudflare_workers_route" "api" {
  zone_id = var.cloudflare_zone_id
  pattern = "api.${var.domain_name}/*"
  script  = cloudflare_workers_script.api_proxy.script_name
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

# =============================================================================
# Cloudflare Worker for api-mock (mock.domain.com)
# =============================================================================

resource "cloudflare_workers_script" "mock_proxy" {
  account_id  = var.cloudflare_account_id
  script_name = "${var.project_name}-mock-proxy"

  content = <<-EOF
    export default {
      async fetch(request, env) {
        const url = new URL(request.url);

        url.hostname = env.CLOUD_RUN_HOST;
        url.protocol = "https:";

        const response = await fetch(url.toString(), {
          method: request.method,
          headers: request.headers,
          body: request.body,
          redirect: "follow"
        });

        return response;
      }
    }
  EOF

  main_module = "worker.js"

  bindings = [
    {
      name = "CLOUD_RUN_HOST"
      type = "plain_text"
      text = trimprefix(trimprefix(google_cloud_run_v2_service.api_mock.uri, "https://"), "http://")
    }
  ]
}

resource "cloudflare_workers_route" "mock" {
  zone_id = var.cloudflare_zone_id
  pattern = "mock.${var.domain_name}/*"
  script  = cloudflare_workers_script.mock_proxy.script_name
}

resource "cloudflare_dns_record" "mock" {
  zone_id = var.cloudflare_zone_id
  name    = "mock"
  type    = "A"
  content = "192.0.2.1"
  ttl     = 1
  proxied = true

  comment = "Mock API endpoint - Cloudflare Worker proxy to Cloud Run (managed by Terraform)"
}
