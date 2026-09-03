#!/usr/bin/env python3
"""Fail closed on non-portable production sources and false-green CI."""

import json
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

for relative in (
    "android-global/i18n_doit.py",
    "android-global/i18n_process.py",
    "backend/fix_text_wrapping.py",
    "backend/scripts/import_knowledge_base.py",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    if "/Users/" in source or "C:\\Users\\" in source:
        errors.append(f"{relative}: production helper contains a developer-machine path")

for knowledge_file in ("顺时知识库_中文版.md", "顺时知识库_补充篇_中文版.md"):
    if not (ROOT / "参考文档，知识库" / knowledge_file).is_file():
        errors.append(f"参考文档，知识库/{knowledge_file}: required RAG source is missing")

rag_loader = (ROOT / "backend/app/rag/knowledge_base.py").read_text(encoding="utf-8")
for required in ("参考文档，知识库", "source_manifest.json", "verified_cn.md"):
    if required not in rag_loader:
        errors.append(f"backend/app/rag/knowledge_base.py: runtime RAG source missing {required!r}")
rag_evidence = (ROOT / "backend/app/rag/evidence.py").read_text(encoding="utf-8")
for required in ("verified_official", "valid_until", "date.today()"):
    if required not in rag_evidence:
        errors.append(f"backend/app/rag/evidence.py: verified RAG gate missing {required!r}")
for relative in ("backend/app/router/chat.py", "backend/app/routers/chat.py"):
    chat_source = (ROOT / relative).read_text(encoding="utf-8")
    if "verified_cn_context" not in chat_source:
        errors.append(f"{relative}: verified RAG context is not connected")

admin_manifest = json.loads((ROOT / "admin/package.json").read_text(encoding="utf-8"))
if not admin_manifest.get("scripts", {}).get("test"):
    errors.append("admin/package.json: fail-closed test command is required")
admin_api = (ROOT / "admin/src/lib/api.ts").read_text(encoding="utf-8")
if "process.env.NEXT_PUBLIC_ADMIN_TOKEN" in admin_api:
    errors.append("admin/src/lib/api.ts: public bundles must never contain an admin token")

ci_source = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
for forbidden in ("--passWithNoTests", "continue-on-error: true", "|| true"):
    if forbidden in ci_source:
        errors.append(f".github/workflows/ci.yml: forbidden false-green option {forbidden}")

payment_sources = {
    "backend/app/router/subscription.py": ("mock=1", "MOCK_QR_CODE", "MOCK_TRADE", "_mock_verify_receipt"),
    "backend/app/router/stripe.py": ("mock=1", "mock_portal", "sk_test_placeholder", "直接解析 JSON"),
    "backend/app/router/notifications.py": ("Push-MOCK", '"provider": "mock"', '"message_id": f"mock_'),
    "backend/app/router/seasons_subscription.py": ("checkout.seasons.app/session", "Mock offer codes", "json.loads(body)", "In production, verify the Stripe signature"),
    "backend/app/services/alipay_service.py": ('ALIPAY_MODE", "mock', "跳过回调验签"),
    "backend/app/services/wechat_pay_service.py": ("MOCK_TRANSACTION", "跳过回调验签"),
    "android-cn/lib/presentation/pages/subscription/subscription_page_v2.dart": ("_simulatePaymentSuccess", "setBool('is_subscribed', true)"),
    "ios-cn/lib/data/datasources/subscription_service.dart": ("_mockOrder",),
    "ios-cn/lib/presentation/pages/subscription/subscription_page_v2.dart": ("setBool('is_subscribed', true)",),
}
for relative, forbidden_values in payment_sources.items():
    source = (ROOT / relative).read_text(encoding="utf-8")
    for forbidden in forbidden_values:
        if forbidden in source:
            errors.append(f"{relative}: forbidden synthetic payment behavior {forbidden!r}")

subscription_source = (ROOT / "backend/app/router/subscription.py").read_text(encoding="utf-8")
for required in ('"code": "payment_required"', "付费会员请通过创建订单接口完成支付"):
    if required not in subscription_source:
        errors.append(f"backend/app/router/subscription.py: legacy paid subscription bypass is not closed ({required!r})")
for forbidden in ("cs_test_mock", "verified = True", "_mock_verify_receipt"):
    if forbidden in subscription_source:
        errors.append(f"backend/app/router/subscription.py: synthetic payment acceptance remains ({forbidden!r})")
for required in (
    "国内版不支持 Stripe，请使用支付宝或微信支付",
    "国内版 Stripe 回调已停用",
    "客户端验签入口已停用",
    "请使用 POST /verify-receipt-v2",
):
    if required not in subscription_source:
        errors.append(f"backend/app/router/subscription.py: unsafe legacy payment route is not retired ({required!r})")

wechat_service = (ROOT / "backend/app/services/wechat_pay_service.py").read_text(encoding="utf-8")
for required in (
    "WECHATPAY2-SHA256-RSA2048",
    "AEAD_AES_256_GCM",
    "WECHAT_PAY_PLATFORM_SERIAL_NO",
    "abs(int(time.time()) - epoch) > 300",
    'amount": {"total": int(product["price_cents"]), "currency": "CNY"}',
):
    if required not in wechat_service:
        errors.append(f"backend/app/services/wechat_pay_service.py: verified WeChat Pay flow is missing {required!r}")

wechat_callback = (ROOT / "backend/app/router/wechat_pay.py").read_text(encoding="utf-8")
for required in ("activate_verified_domestic_payment", 'amount.get("currency") != "CNY"'):
    if required not in wechat_callback:
        errors.append(f"backend/app/router/wechat_pay.py: verified activation is missing {required!r}")

apple_receipt = (ROOT / "backend/app/services/apple_receipt.py").read_text(encoding="utf-8")
for required in ('if not bundle_id or bundle_id != BUNDLE_ID:', '"valid": False', "Apple 收据所属应用不匹配"):
    if required not in apple_receipt:
        errors.append(f"backend/app/services/apple_receipt.py: receipt ownership validation is missing {required!r}")

android_payment_ui = (ROOT / "android-cn/lib/presentation/pages/subscription/subscription_page_v2.dart").read_text(encoding="utf-8")
for required in ("WechatPayClient.pay", "QrImageView", "pollOrderStatus", "status == 'paid'"):
    if required not in android_payment_ui:
        errors.append(f"android-cn/lib/presentation/pages/subscription/subscription_page_v2.dart: real payment flow is missing {required!r}")

ios_payment_ui = (ROOT / "ios-cn/lib/presentation/pages/subscription/subscription_page_v2.dart").read_text(encoding="utf-8")
for required in ("StoreService", "purchase('yiyang_yearly')", "服务端验证收据"):
    if required not in ios_payment_ui:
        errors.append(f"ios-cn/lib/presentation/pages/subscription/subscription_page_v2.dart: App Store flow is missing {required!r}")

for relative in (
    "android-cn/lib/data/services/store_service.dart",
    "ios-cn/lib/data/services/store_service.dart",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    if "return true; // 模拟模式" in source or "pendingCompletePurchase && platformVerified" not in source:
        errors.append(f"{relative}: store receipt validation must fail closed before completing a purchase")

for relative in (
    "android-cn/lib/data/datasources/subscription_service.dart",
    "ios-cn/lib/data/datasources/subscription_service.dart",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    for required in ("Authorization", "Bearer $token", "StorageManager.user.getToken"):
        if required not in source:
            errors.append(f"{relative}: authenticated subscription flow is missing {required!r}")

for relative in (
    "android-cn/lib/presentation/pages/login/login_page.dart",
    "ios-cn/lib/presentation/pages/login/login_page.dart",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    if "data['access_token']" not in source:
        errors.append(f"{relative}: login must persist the backend access_token")

for relative in (
    "android-cn/lib/presentation/pages/chat_page.dart",
    "ios-cn/lib/presentation/pages/chat_page.dart",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    for forbidden in ("宜食银耳、百合润燥之物", "《黄帝内经·素问》", "《本草纲目》"):
        if forbidden in source:
            errors.append(f"{relative}: offline mode fabricates health evidence {forbidden!r}")
    if "离线状态不生成健康建议" not in source:
        errors.append(f"{relative}: offline health response must fail closed")

entries = subprocess.run(
    ["git", "ls-files", "-s", "-z"], cwd=ROOT, check=True, capture_output=True, text=True
).stdout.split("\0")
for entry in entries:
    if not entry or not entry.startswith("120000 "):
        continue
    relative = entry.split("\t", 1)[1]
    link = ROOT / relative
    target = os.readlink(link)
    if os.path.isabs(target):
        errors.append(f"{relative}: tracked symlink must be relative")
    elif not link.exists():
        errors.append(f"{relative}: tracked symlink target is missing ({target})")

if errors:
    raise SystemExit("Repository integrity gate failed:\n- " + "\n- ".join(errors))

print("Repository integrity gate passed")
