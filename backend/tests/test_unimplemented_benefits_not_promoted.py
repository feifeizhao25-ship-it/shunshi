"""定稿(2026-10-18): deep_suggestions/weekly_summary 无执行点, 后端权益一律 False 且前端订阅页不得宣传."""
import json, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
REG = json.loads((ROOT/"app/entitlements_registry.json").read_text())

def test_registry_weekly_deep_report_all_false():
    for name, tier in REG["tiers"].items():
        assert tier["knowledge"]["weekly_deep_report"] is False, name

def test_frontend_subscription_pages_do_not_promote_unimplemented():
    cn = (ROOT.parent/"android-cn/lib/presentation/pages/subscription/subscription_page_v2.dart").read_text()
    assert "周度深度报告" not in cn and "长期趋势与周度报告" not in cn
    intl = (ROOT.parent/"android-global/lib/data/datasources/subscription_service.dart").read_text()
    assert "'deep_suggestions': true" not in intl and "'weekly_summary': true" not in intl
    assert "Deep suggestions + weekly summary" not in intl
