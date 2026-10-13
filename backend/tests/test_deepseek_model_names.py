"""DeepSeek 官方 2026-07-24 停用 deepseek-chat / deepseek-reasoner（更新日志 2026-04-24 条目）。
国内对话主路径与 DeepSeek 客户端都不能再发出旧名。"""
from app.llm import deepseek, domestic_gateway
from app.core.settings import Settings


def test_retired_names_map_to_current_models():
    m = deepseek.MODEL_NAME_MAP
    assert m["deepseek-chat"] == "deepseek-flash"
    assert m["deepseek-reasoner"] == "deepseek-v4-pro"
    assert m["deepseek-v4"] == "deepseek-flash"
    assert m["deepseek-r1"] == "deepseek-v4-pro"
    assert set(m.values()) <= {"deepseek-flash", "deepseek-v4-pro"}


def test_domestic_gateway_and_default_use_current_name():
    ds = [p for p in domestic_gateway.PROVIDERS if p.name == "deepseek"][0]
    assert ds.model == "deepseek-flash"
    assert Settings.model_fields["DEFAULT_LLM_MODEL"].default == "deepseek-flash"
