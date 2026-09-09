# 国内后台依赖修复

GitHub CI 在 2026-09-09 的生产依赖审计发现 Next.js 和 sharp 漏洞并阻止后续构建。后台现将 Next.js 与 eslint-config-next 固定为 16.3.4，sharp 锁定结果为 0.35.4，并更新开发依赖链中被审计标记的 tar、js-yaml、brace-expansion、picomatch 与 humanfs。

依据：[Next.js 维护者公告](https://github.com/vercel/next.js/security/advisories/GHSA-2xp9-vwfh-vxw4)、[sharp 维护者公告](https://github.com/lovell/sharp/security/advisories/GHSA-rgj7-g3m4-5g8c)，2026-09-09 查阅。未通过关闭审计或降低严重程度门槛放行。

验证：完整 npm audit（包含开发依赖）0 个已知漏洞，lint、后台契约测试及 Next.js 生产构建通过。结果基于当时 npm 审计数据库，不代表未来没有新漏洞或真实生产部署已通过。当前代码与部署剩余问题见国内支付增量审查和生产外部配置文档。
