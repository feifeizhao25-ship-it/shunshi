# app/routers — 核心路由包（仍在用，勿删）

2026-10-18 定稿隔离说明：本包由 `app/main.py` 显式挂载（chat / user / subscription /
memory / reflections / seasons / settings / content / feedback / health），是国内版对话与
账户主链路，**不是废弃代码**。与单数目录 `app/router/`（自动发现的产品路由）同名同路径时，
main.py 按“已挂载者优先”去重，后挂的同路径路由不可达。改接口前先确认你要改的是哪一套，
并用路由清单测试验证最终生效的是目标实现。国际专用模块在 main.py 的
INTERNATIONAL_ONLY_MODULES 中排除，待药师/中医审核的 tcm_medication 在
PENDING_REVIEW_MODULES 中保持不挂载（fail-closed）。
