# 顺时 ShunShi 部署架构

## 部署阶段

| 阶段 | 用户规模 | 架构 | 成本 |
|------|----------|------|------|
| Dev | < 1K | 单机 Docker | ¥1K/月 |
| Staging | < 10K | Docker Compose | ¥3K/月 |
| Prod 1 | < 100K | K8s 2-4 节点 | ¥10K/月 |
| Prod 2 | < 1M | K8s 10+ 节点 | ¥50K/月 |
| Prod 3 | < 10M | 多地域 + CDN | ¥200K/月 |

---

## Dev 环境 (单机)

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/shunshi
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7

volumes:
  postgres_data:
```

---

## Staging 环境

```yaml
# docker-compose.staging.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api

  api:
    build: ./backend
    replicas: 2
    environment:
      - ENV=staging

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Prod 环境 (K8s)

### K8s 部署架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         CDN (阿里云)                              │
│                      dcdn.aliyuncs.com                          │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    API Gateway (Nginx Ingress)                  │
│                         k8s Ingress                             │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐     ┌───────▼───────┐     ┌───────▼───────┐
│  Auth Pod     │     │   Chat Pod    │     │ Wellness Pod  │
│    x 2        │     │     x 3        │     │     x 2       │
└───────────────┘     └───────────────┘     └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                      AI Router Service                           │
│                         x 3 pods                                │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐     ┌───────▼───────┐     ┌───────▼───────┐
│  小模型 7B    │     │   大模型 72B   │     │  Skills Pod   │
│   (vLLM)     │     │    (API)      │     │     x 2       │
└───────────────┘     └────────────────┘     └───────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                                │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐               │
│  │ PostgreSQL │   │   Redis    │   │    OSS     │               │
│  │  主从复制   │   │   Cluster  │   │   文件存储  │               │
│  └────────────┘   └────────────┘   └────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### Helm Chart

```yaml
# helm/shunshi/values.yaml
replicaCount: 3

image:
  repository: registry.cn-shanghai.aliyuncs.com/shunshi/api
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8000

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  hosts:
    - host: api.shunshi.com
      paths:
        - path: /
          pathType: Prefix

config:
  DATABASE_URL: "postgresql://user:pass@postgres:5432/shunshi"
  REDIS_URL: "redis://redis:6379"
  LLM_API_KEY: "${LLM_API_KEY}"

persistence:
  enabled: true
  storageClass: "alicloud-disk-efficiency"
  accessMode: ReadWriteOnce
  size: 20Gi
```

---

## 灰度发布与回滚

### Argo Rollouts 配置

```yaml
# argo-rollouts.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: shunshi-api
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: {duration: 10m}
        - setWeight: 30
        - pause: {duration: 10m}
        - setWeight: 50
        - pause: {duration: 10m}
        - setWeight: 100
      canaryService: shunshi-api-canary
      stableService: shunshi-api-stable
      trafficRouting:
        nginx:
          stableIngress: shunshi-ingress
      abort:
        - setWeight: 0
        - pause: {duration: 5m}
```

### 灰度命令

```bash
# 查看 rollout 状态
kubectl get rollout shunshi-api

# 暂停 rollout
kubectl argo rollouts pause shunshi-api

# 继续 rollout
kubectl argo rollouts promote shunshi-api

# 中止并回滚
kubectl argo rollouts abort shunshi-api
kubectl argo rollouts undo shunshi-api

# 回滚到上一版本
kubectl argo rollouts undo shunshi-api --to-revision=3
```

---

## 监控与告警

### Prometheus + Grafana

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: shunshi-alerts
spec:
  groups:
    - name: shunshi
      rules:
        - alert: HighErrorRate
          expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High error rate detected"
        
        - alert: HighLatency
          expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 3
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High latency detected"
        
        - alert: LLMErrors
          expr: rate(llm_errors_total[5m]) > 0.1
          for: 2m
          labels:
            severity: critical
        
        - alert: PodMemoryHigh
          expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
          for: 5m
          labels:
            severity: warning
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "顺时监控面板",
    "panels": [
      {
        "title": "请求量",
        "type": "graph",
        "targets": [
          {"expr": "rate(http_requests_total[5m])"}
        ]
      },
      {
        "title": "响应时间 P95",
        "type": "graph",
        "targets": [
          {"expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"}
        ]
      },
      {
        "title": "错误率",
        "type": "graph",
        "targets": [
          {"expr": "rate(http_requests_total{status=~\"5..\"}[5m])"}
        ]
      },
      {
        "title": "LLM 调用延迟",
        "type": "graph",
        "targets": [
          {"expr": "histogram_quantile(0.95, rate(llm_duration_seconds_bucket[5m]))"}
        ]
      }
    ]
  }
}
```

---

## 日志系统

### ELK Stack

```yaml
# filebeat-config.yaml
filebeat.inputs:
  - type: container
    paths:
      - /var/lib/docker/containers/*/*.log
    processors:
      - add_kubernetes_metadata:
          in_cluster: true

output.logstash:
  hosts: ["logstash:5044"]
```

### 日志查询

```bash
# 查询最近 1 小时的错误日志
kubectl logs -l app=shunshi-api --since=1h | grep ERROR

# 查询特定用户的请求
kubectl logs -l app=shunshi-api | grep "user_id=xxx"

# 使用 Loki 查询
logql='{app="shunshi-api"} |= "ERROR" | json'
```

---

## 环境管理

### 环境变量

```bash
# .env.production
# 数据库
DATABASE_URL=postgresql://user:password@rm-xxx.rds.aliyuncs.com:5432/shunshi
DATABASE_POOL_SIZE=20

# Redis
REDIS_URL=redis://r-xxx.redis.rds.aliyuncs.com:6379

# LLM
OPENAI_API_KEY=sk-xxx
ANTHROPIC_API_KEY=sk-ant-xxx

# 阿里云
ALIYUN_ACCESS_KEY_ID=xxx
ALIYUN_ACCESS_KEY_SECRET=xxx
OSS_BUCKET=shunshi-prod

# 业务
JWT_SECRET=xxx
SESSION_SECRET=xxx

# 监控
SENTRY_DSN=https://xxx@sentry.io/xxx
```

### 环境切换

```bash
# 部署到不同环境
kubectl config use-context staging
helm upgrade --install shunshi ./helm/shunshi -n shunshi --create-namespace

kubectl config use-context production
helm upgrade --install shunshi ./helm/shunshi -n shunshi --create-namespace
```

---

## 安全配置

### 网络策略

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shunshi-api
spec:
  podSelector:
    matchLabels:
      app: shunshi-api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: nginx-ingress
      ports:
        - protocol: TCP
          port: 8000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
```

### 密钥管理

```bash
# 使用 Sealed Secrets 加密敏感配置
kubectl create secret generic shunshi-secrets \
  --from-literal=database-url='postgresql://...' \
  --from-literal=jwt-secret='...' \
  --dry-run=client -o json > sealed-secret.json

# 解密
kubeseal --format json < sealed-secret.json > unsealed-secret.json
```
