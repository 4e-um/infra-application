# Infrastructure Application

GKE AutoPilot, CloudSQL, Redis, Cloud Run Job 등 애플리케이션 인프라를 생성하는 Terraform 모듈입니다.

## 생성되는 리소스

| 리소스 | 설명 |
|--------|------|
| GKE AutoPilot | API 서비스 배포용 Kubernetes 클러스터 |
| CloudSQL PostgreSQL | 메인 데이터베이스 (db-f1-micro) |
| Redis VMs (x2) | api-usage, api-message용 캐시 (e2-micro) |
| Cloud Run Job | batch-core 배치 작업 |
| Cloud Scheduler | 월간 배치 스케줄러 |
| Artifact Registry | Docker 이미지 저장소 |
| Secret Manager | 민감 정보 저장 |
| Service Accounts | 워크로드별 서비스 계정 |
| VPC Connector | Cloud Run VPC 연결 |
| GitHub Actions WIF | CI/CD 인증 |
| Cloudflare DNS | API 도메인 설정 |
| **K8s Namespace** | app 네임스페이스 (Terraform 관리) |
| **K8s Secrets** | DB, Redis, Kafka 자격증명 (Terraform 관리) |
| **K8s Service Accounts** | Workload Identity 바인딩 (Terraform 관리) |
| **K8s Ingress** | GCE Ingress + BackendConfig (Terraform 관리) |

## 아키텍처

```
                          [Internet]
                               │
                         [Cloudflare]
                        (SSL Termination)
                               │
                [Cloud Load Balancer - HTTP]
                               │
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
  [api-core]             [api-usage]            [api-message]
       │                       │                       │
       │                [Redis-usage]          [Redis-message]
       │                  (e2-micro)             (e2-micro)
       │                       │                       │
       └───────────────────────┼───────────────────────┘
                               │
                     [GKE AutoPilot Cluster]
                               │
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
  [CloudSQL]           [Confluent Cloud]       [Secret Manager]
  (PostgreSQL)             (Kafka)

[Cloud Scheduler] ──► [Cloud Run Job: batch-core]
   (월 1회)                    │
                         [CloudSQL 연결]
```

## 사전 요구사항

1. **infra-bootstrap 배포 완료**: 프로젝트, VPC가 먼저 생성되어야 함
2. **Terraform Cloud/Scalr**: 워크스페이스 생성
3. **Confluent Cloud**: Kafka 클러스터 (기존 사용)
4. **Cloudflare**: 도메인 및 Zone ID

## Terraform Cloud/Scalr 설정

### 1. 워크스페이스 생성

- Name: `telecom-app-dev`
- VCS: 이 저장소 연결
- Working Directory: `-infra/infra-application`

### 2. Remote State 공유 설정

bootstrap 워크스페이스의 상태를 이 워크스페이스에서 읽을 수 있도록 설정:

- Terraform Cloud: Settings → General → Remote state sharing
- `telecom-app-bootstrap` 워크스페이스 공유 허용

### 3. 변수 설정

#### Required Variables

| Variable | Type | Sensitive | Description |
|----------|------|-----------|-------------|
| `terraform_cloud_org` | string | No | Terraform Cloud 조직명 |
| `database_password` | string | **Yes** | PostgreSQL 비밀번호 |
| `redis_usage_password` | string | **Yes** | Redis (usage) 비밀번호 |
| `redis_message_password` | string | **Yes** | Redis (message) 비밀번호 |
| `kafka_bootstrap_servers` | string | No | Kafka 서버 주소 |
| `kafka_api_key` | string | **Yes** | Kafka API Key |
| `kafka_api_secret` | string | **Yes** | Kafka API Secret |
| `cloudflare_api_token` | string | **Yes** | Cloudflare API 토큰 |
| `cloudflare_zone_id` | string | No | Cloudflare Zone ID |
| `domain_name` | string | No | 도메인 (예: example.com) |

#### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bootstrap_workspace_name` | string | `"telecom-app-bootstrap"` | Bootstrap 워크스페이스명 |
| `project_name` | string | `"telecom-app"` | 리소스 이름 접두사 |
| `environment` | string | `"dev"` | 환경 |
| `database_tier` | string | `"db-f1-micro"` | CloudSQL 인스턴스 타입 |
| `database_disk_size` | number | `10` | CloudSQL 디스크 크기 (GB) |
| `redis_machine_type` | string | `"e2-micro"` | Redis VM 타입 |
| `batch_cpu_limit` | string | `"2"` | Batch Job CPU |
| `batch_memory_limit` | string | `"2Gi"` | Batch Job 메모리 |
| `batch_timeout` | string | `"3600s"` | Batch Job 타임아웃 |
| `github_org` | string | `""` | GitHub 조직명 |
| `github_repos` | list | `["api-core", ...]` | GitHub 저장소 목록 |
| `aes_secret_key` | string | `""` | AES 암호화 키 (32자) |

### 4. 환경 변수

| Variable | Description |
|----------|-------------|
| `GOOGLE_CREDENTIALS` | GCP Service Account JSON 키 |
| `CLOUDFLARE_API_TOKEN` | (선택) Provider 인증용 |

## Outputs

| Output | Description |
|--------|-------------|
| `gke_cluster_name` | GKE 클러스터 이름 |
| `gke_cluster_endpoint` | GKE API 엔드포인트 (sensitive) |
| `gke_get_credentials_command` | kubectl 연결 명령어 |
| `cloudsql_instance_name` | CloudSQL 인스턴스 이름 |
| `cloudsql_connection_name` | CloudSQL 연결 이름 |
| `cloudsql_private_ip` | CloudSQL 프라이빗 IP |
| `redis_usage_private_ip` | Redis (usage) 프라이빗 IP |
| `redis_usage_external_ip` | Redis (usage) 외부 IP |
| `redis_message_private_ip` | Redis (message) 프라이빗 IP |
| `redis_message_external_ip` | Redis (message) 외부 IP |
| `artifact_registry_url` | Artifact Registry URL |
| `cloudrun_job_name` | Cloud Run Job 이름 |
| `load_balancer_ip` | 로드밸런서 IP |
| `api_domain` | API 도메인 |
| `github_actions_sa_email` | GitHub Actions SA 이메일 |
| `github_actions_workload_identity_provider` | WIF Provider |
| `github_actions_config` | GitHub Actions 설정 예시 |

## 배포 후 작업

Terraform apply 완료 시 자동으로 생성되는 K8s 리소스:
- Namespace (`app`)
- Secrets (DB, Redis, Kafka 자격증명 - Terraform outputs 사용)
- Service Accounts (Workload Identity 바인딩)
- Ingress + BackendConfig

### 1. GKE 연결

```bash
# 출력된 명령어 실행
gcloud container clusters get-credentials telecom-app-cluster \
  --region asia-northeast3 \
  --project <PROJECT_ID>
```

### 2. 각 서비스 Deployment/Service 배포

K8s 기본 리소스는 Terraform이 관리하므로, 각 서비스의 Deployment와 Service만 배포:

```bash
# api-core (serviceaccount 제외 - Terraform이 생성)
kubectl apply -f -backends/api-core/k8s/deployment.yaml
kubectl apply -f -backends/api-core/k8s/service.yaml
kubectl apply -f -backends/api-core/k8s/hpa.yaml

# api-usage
kubectl apply -f -backends/api-usage/k8s/deployment.yaml
kubectl apply -f -backends/api-usage/k8s/service.yaml
kubectl apply -f -backends/api-usage/k8s/hpa.yaml

# api-message
kubectl apply -f -backends/api-message/k8s/deployment.yaml
kubectl apply -f -backends/api-message/k8s/service.yaml
kubectl apply -f -backends/api-message/k8s/hpa.yaml
```

또는 GitHub Actions가 자동으로 배포 (main 브랜치 push 시)

### 3. GitHub Actions 설정

Outputs의 `github_actions_config` 참고하여 워크플로우 설정:

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: 'projects/.../providers/github-provider'
    service_account: 'telecom-app-github-actions@....iam.gserviceaccount.com'
```

## 예상 비용 (dev 환경, 월간)

| 리소스 | 사양 | 예상 비용 |
|--------|------|----------|
| GKE AutoPilot | 사용량 기반 | ~$50-100 |
| CloudSQL | db-f1-micro, 10GB | ~$10 |
| Redis VM x2 | e2-micro | ~$14 |
| Cloud Run Job | 실행 시간 기반 | ~$5 |
| Artifact Registry | 저장 용량 기반 | ~$2 |
| **합계** | | **~$81-131/월** |

## 로컬 테스트

```bash
# 초기화 (backend 비활성화)
terraform init -backend=false

# 검증
terraform validate

# 플랜 (bootstrap 연결 없이는 실패)
terraform plan
```

## 파일 구조

```
infra-application/
├── main.tf              # Provider, backend 설정
├── data.tf              # Remote state 참조
├── locals.tf            # 로컬 변수
├── variables.tf         # 입력 변수
├── outputs.tf           # 출력값
├── vpc.tf               # VPC Connector, LB IP
├── firewall.tf          # Redis 외부 접근 규칙
├── gke.tf               # GKE AutoPilot
├── cloudsql.tf          # CloudSQL PostgreSQL
├── redis.tf             # Redis 모듈 호출
├── cloudrun-job.tf      # Cloud Run Job
├── cloud-scheduler.tf   # Cloud Scheduler
├── artifact-registry.tf # Artifact Registry
├── service-accounts.tf  # 서비스 계정
├── secret-manager.tf    # Secret Manager
├── iam.tf               # IAM 바인딩
├── github-actions.tf    # GitHub WIF
├── cloudflare.tf        # DNS 레코드
├── kubernetes.tf        # K8s 리소스 (Namespace, Secrets, SA, Ingress)
└── modules/
    └── redis/           # Redis VM 모듈
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
