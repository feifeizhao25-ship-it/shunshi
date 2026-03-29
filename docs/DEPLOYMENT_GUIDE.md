# 顺时 (Shunshi) 部署指南

## 目录

1. [本地开发环境](#1-本地开发环境)
2. [Docker Compose 一键启动](#2-docker-compose-一键启动)
3. [K8s 生产部署](#3-k8s-生产部署)
4. [环境变量说明](#4-环境变量说明)
5. [数据库迁移](#5-数据库迁移)
6. [SSL 证书配置](#6-ssl-证书配置)
7. [监控访问](#7-监控访问)
8. [备份与恢复](#8-备份与恢复)
9. [故障排查](#9-故障排查)

---

## 1. 本地开发环境

### 前置要求

- Python 3.12+
- Node.js 20+
- Flutter 3.24.0+
- Docker & Docker Compose
- Git

### 后端

```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 复制并编辑环境变量
cp .env.example .env
# 编辑 .env 填入实际值

# 启动服务 (默认 SQLite)
uvicorn app.main:app --reload --port 4000

# 或使用 MySQL (需先启动 MySQL)
DATABASE_URL=mysql+pymysql://user:pass@localhost:3306/shunshi \
  uvicorn app.main:app --reload --port 4000
```

### Web 管理后台

```bash
cd web-admin

# 安装依赖
npm ci

# 开发模式
npm run dev

# 构建
npm run build
```

### Flutter App

```bash
# 国内版
cd android-cn   # 或 ios-cn
flutter pub get
flutter run

# 海外版
cd android-global   # 或 ios-global
flutter pub get
flutter run
```

---

## 2. Docker Compose 一键启动

### 快速启动

```bash
# 1. 配置环境变量
cp backend/.env.example backend/.env
# 编辑 backend/.env 中的密码和 API Key

# 2. 一键启动所有服务
docker compose up -d

# 3. 查看服务状态
docker compose ps

# 4. 查看日志
docker compose logs -f backend
```

### 服务端口

| 服务         | 端口   | 说明                    |
|------------|--------|-----------------------|
| Nginx      | 80/443 | 主入口 (API + Web 后台)   |
| Backend    | 4000   | FastAPI (直接访问)      |
| MySQL      | 3306   | 数据库                  |
| Redis      | 6379   | 缓存                   |
| Grafana    | 3000   | 监控面板 (admin/admin)  |
| Prometheus | 9090   | 指标采集                |

### 常用命令

```bash
# 停止所有服务
docker compose down

# 停止并清除数据卷
docker compose down -v

# 重建某个服务
docker compose up -d --build backend

# 查看资源使用
docker stats

# 进入容器
docker compose exec backend bash
docker compose exec mysql mysql -u shunshi -p shunshi123 shunshi
```

### 网络

Docker Compose 使用三个隔离网络：

- **backend-net**: MySQL + Redis + Backend 之间的内部通信
- **frontend-net**: Backend + Web Admin + Nginx 之间的通信
- **monitoring-net**: Prometheus + Grafana 之间的通信

---

## 3. K8s 生产部署

### 前置要求

- kubectl 已配置并连接到目标集群
- 确保有集群管理员权限

### 部署步骤

```bash
# 1. 创建命名空间
kubectl apply -f k8s/namespace.yaml

# 2. 配置 ConfigMap (非敏感配置)
# 先检查并修改 k8s/configmap.yaml
kubectl apply -f k8s/configmap.yaml

# 3. 配置 Secret (敏感配置)
# ⚠️ 修改 k8s/secret.yaml 中的 base64 值
# echo -n 'your_password' | base64
kubectl apply -f k8s/secret.yaml

# 4. 部署 MySQL (StatefulSet)
kubectl apply -f k8s/mysql-statefulset.yaml

# 5. 部署 Redis
kubectl apply -f k8s/redis-deployment.yaml

# 6. 等待数据库就绪
kubectl -n shunshi rollout status statefulset/mysql --timeout=300s
kubectl -n shunshi rollout status deployment/redis --timeout=120s

# 7. 部署后端
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# 8. 部署 Web 管理后台
kubectl apply -f k8s/web-admin.yaml

# 9. 部署 Nginx + Ingress
kubectl apply -f k8s/nginx-configmap.yaml
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/ingress.yaml

# 10. 配置自动扩缩
kubectl apply -f k8s/hpa.yaml

# 11. 验证
kubectl -n shunshi get all
```

### 更新部署

```bash
# 更新镜像版本
kubectl -n shunshi set image deployment/backend backend=shunshi/backend:sha-xxxxx
kubectl -n shunshi set image deployment/web-admin web-admin=shunshi/web-admin:sha-xxxxx

# 查看滚动更新状态
kubectl -n shunshi rollout status deployment/backend

# 回滚
kubectl -n shunshi rollout undo deployment/backend
```

### 一键部署所有

```bash
kubectl apply -f k8s/ --recursive
```

---

## 4. 环境变量说明

| 变量                  | 说明                  | 默认值                          | 必需 |
|---------------------|---------------------|-------------------------------|------|
| `DATABASE_URL`      | SQLite 连接 (本地开发)   | `sqlite:///data/shunshi.db`   | 否    |
| `MYSQL_HOST`        | MySQL 主机           | `mysql`                       | 是    |
| `MYSQL_PORT`        | MySQL 端口           | `3306`                        | 是    |
| `MYSQL_USER`        | MySQL 用户           | `shunshi`                     | 是    |
| `MYSQL_PASSWORD`    | MySQL 密码           | *(需修改)*                     | 是    |
| `MYSQL_DATABASE`    | 数据库名              | `shunshi`                     | 是    |
| `REDIS_URL`         | Redis 连接           | `redis://redis:6379/0`       | 是    |
| `JWT_SECRET`        | JWT 签名密钥          | *(需修改)*                     | 是    |
| `SILICONFLOW_API_KEY`| SiliconFlow API Key | *(需修改)*                     | 是    |
| `FLUTTER_APP_URL`   | Flutter App 深度链接地址 | `http://localhost:3007`       | 否    |
| `SENTRY_DSN`        | Sentry 错误监控 DSN   | *(空=禁用)*                    | 否    |
| `LOG_LEVEL`         | 日志级别              | `INFO`                        | 否    |

---

## 5. 数据库迁移

### 初始化

MySQL 容器首次启动时会自动执行 `backend/docker/mysql/init.sql`。

### 手动执行迁移

```bash
# Docker 环境
docker compose exec mysql mysql -u root -p shunshi < backend/docker/mysql/init.sql

# K8s 环境
kubectl -n shunshi exec -it mysql-0 -- mysql -u root -p shunshi < init.sql
```

### 数据备份

```bash
# Docker
docker compose exec mysql mysqldump -u root -p shunshi > backup_$(date +%Y%m%d).sql

# K8s
kubectl -n shunshi exec mysql-0 -- mysqldump -u root -p shunshi > backup.sql
```

### 数据恢复

```bash
# Docker
docker compose exec -T mysql mysql -u root -p shunshi < backup.sql

# K8s
kubectl -n shunshi exec -i mysql-0 -- mysql -u root -p shunshi < backup.sql
```

---

## 6. SSL 证书配置

### Let's Encrypt (推荐)

```bash
# 安装 cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# 创建 ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# 取消 k8s/ingress.yaml 中 TLS 和 cert-manager 注释
# 重新 apply
kubectl apply -f k8s/ingress.yaml
```

### 手动证书

```bash
# 将证书放入 backend/docker/ssl/
cp fullchain.pem backend/docker/ssl/cert.pem
cp privkey.pem backend/docker/ssl/key.pem

# 取消 docker/nginx/conf.d/default.conf 中 HTTPS server 块注释
# 重新启动 nginx
docker compose up -d nginx
```

---

## 7. 监控访问

### Grafana

- URL: http://localhost:3000
- 默认账号: `admin` / `admin`
- 已预配置 Prometheus 数据源和顺时后端 Dashboard

### Prometheus

- URL: http://localhost:9090
- 后端指标路径: `/metrics`
- 数据保留: 30 天

### 后端健康检查

```bash
curl http://localhost:4000/health
```

---

## 8. 备份与恢复

### Docker 环境完整备份

```bash
# 1. 备份数据库
docker compose exec mysql mysqldump -u root -p shunshi > backup_mysql_$(date +%Y%m%d_%H%M%S).sql

# 2. 备份 Redis
docker compose exec redis redis-cli BGSAVE
docker cp shunshi-redis:/data/dump.rdb backup_redis_$(date +%Y%m%d_%H%M%S).rdb

# 3. 备份 Docker 卷
docker run --rm -v shunshi_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_data_$(date +%Y%m%d).tar.gz /data
```

### 恢复

```bash
# 恢复 MySQL
docker compose exec -T mysql mysql -u root -p shunshi < backup_mysql_20260317.sql

# 恢复 Redis
docker cp backup_redis.rdb shunshi-redis:/data/dump.rdb
docker compose restart redis
```

---

## 9. 故障排查

### 后端无法启动

```bash
# 查看日志
docker compose logs backend --tail=100

# 常见原因:
# 1. MySQL 未就绪 -> 检查 mysql 容器状态
# 2. 环境变量缺失 -> 检查 .env 文件
# 3. 端口占用 -> lsof -i :4000
```

### 数据库连接失败

```bash
# 检查 MySQL 是否健康
docker compose exec mysql mysqladmin ping -u root -p

# 检查网络连通性
docker compose exec backend python -c "
import socket
s = socket.socket()
s.settimeout(3)
try:
    s.connect(('mysql', 3306))
    print('MySQL reachable')
except Exception as e:
    print(f'Cannot reach MySQL: {e}')
finally:
    s.close()
"
```

### Redis 连接失败

```bash
docker compose exec redis redis-cli ping
# 应返回 PONG
```

### K8s Pod 无法启动

```bash
# 查看 Pod 状态
kubectl -n shunshi get pods

# 查看 Pod 事件
kubectl -n shunshi describe pod <pod-name>

# 查看日志
kubectl -n shunshi logs <pod-name>

# 查看上一次崩溃日志
kubectl -n shunshi logs <pod-name> --previous
```

### HPA 不生效

```bash
# 检查 HPA 状态
kubectl -n shunshi get hpa

# 确认 metrics-server 已安装
kubectl get deployment metrics-server -n kube-system

# 如未安装
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 常用 K8s 调试命令

```bash
# 进入容器
kubectl -n shunshi exec -it <pod-name> -- sh

# 端口转发 (本地调试)
kubectl -n shunshi port-forward svc/backend 4000:4000

# 查看资源使用
kubectl -n shunshi top pods
```
