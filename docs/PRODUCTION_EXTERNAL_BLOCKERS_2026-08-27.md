# 顺时生产上线：必须人工完成的外部配置

> 增量更新：2026-09-09。历史构建记录不代表当前生产验收通过；支付与权益跨存储一致性等代码缺口仍见 `CN_PAYMENT_STATE_REVIEW_2026-09-08.md`。以下部署配置不得包含真实密钥提交入库。

## 1. 准备 Kubernetes 集群

1. 创建生产集群，并安装 Nginx Ingress Controller。
2. 安装 cert-manager，创建名为 `letsencrypt-prod` 的 `ClusterIssuer`。
3. 在本机确认：`kubectl get nodes`、`kubectl get ingressclass nginx`、`kubectl get clusterissuer letsencrypt-prod` 均正常。
4. 生成 GitHub 使用的 kubeconfig；务必限制其 ServiceAccount 仅能管理 `shunshi` 命名空间。
5. 将 kubeconfig 单行编码：`base64 < kubeconfig | tr -d '\n'`。
6. GitHub 仓库进入 **Settings → Secrets and variables → Actions → New repository secret**，创建 `KUBE_CONFIG`，粘贴上一步结果。

## 2. 录入生产 Secrets

在同一页面创建以下必填 Secrets：

| 名称 | 如何获得/生成 |
|---|---|
| `DB_PASSWORD` | `openssl rand -base64 36`；仅用于生产 PostgreSQL |
| `SHUNSHI_DATABASE_URL` | 完整生产 DSN，例如 `postgresql+psycopg2://shunshi:<URL编码密码>@postgres:5432/shunshi` |
| `SHUNSHI_JWT_SECRET` | `openssl rand -hex 32` |
| `JWT_SECRET` | `openssl rand -hex 32`；兼容现有认证路由，不能复用管理员密钥 |
| `ADMIN_JWT_SECRET` | `openssl rand -hex 32` |
| `ADMIN_PASSWORD_HASH` | 使用后台文档指定的密码哈希工具生成，禁止填写明文密码 |
| `SILICONFLOW_API_KEY` | 硅基流动生产账号控制台创建，并设置额度告警与调用限制 |

启用对应功能后再录入：`STRIPE_SECRET_KEY`、`STRIPE_WEBHOOK_SECRET`、`WECHAT_APP_SECRET`。

支付宝须成套配置 `ALIPAY_APP_ID`、`ALIPAY_SELLER_ID`（实际收款商户）、`ALIPAY_PRIVATE_KEY`、`ALIPAY_PUBLIC_KEY`（支付宝验签公钥）、`ALIPAY_NOTIFY_URL`、`ALIPAY_RETURN_URL`。通知地址为实际 API 域名的 `/api/v1/payments/alipay/notify`，两地址均使用 HTTPS；不能沿用未绑定域名的示例地址。工作流在部分配置缺失时阻止部署，全空时支付保持不可用。SDK 已纳入镜像依赖。未完成商户审核、权益一致性修复和商户联调前不能把配置齐全称为收款就绪。

工作流会在部署前逐项检查必填值，并用 `kubectl create secret ... --dry-run | kubectl apply` 注入集群；仓库中的 `k8s/secret.yaml` 只作为字段说明模板，不再被生产工作流应用。

## 3. 域名与证书

1. 将 `shunshi.app` 和 `api.shunshi.app` 的 DNS 记录指向 Ingress 公网地址。
2. 等待 DNS 生效后检查：`dig +short shunshi.app` 和 `dig +short api.shunshi.app`。
3. 执行部署后检查：`kubectl -n shunshi get certificate,challenge,ingress`。
4. 验证 `curl -fsS https://api.shunshi.app/health`，并确认浏览器证书链有效。

当前证书探测结果在不同客户端间不一致，因此必须以部署后的 `curl`、浏览器和 cert-manager 状态三方复验为准。`shunshi.ai` 当前承载另一套命理网站，不应指向本仓库，避免覆盖错误产品。

## 4. 触发与验收

1. 在 GitHub Actions 手动运行 **Deploy**。
2. 确认测试、两个镜像发布、Secret 创建、Kubernetes rollout 全部为绿色。
3. 运行 `kubectl -n shunshi get pods,svc,ingress,hpa`，所有 Pod 必须 Ready。
4. 用新注册测试账号完成：注册/登录、AI 对话、会员权益校验、数据导出与删除、支付沙箱回调。
5. 完成上述验收后才允许切换支付生产密钥并提交应用商店审核。
