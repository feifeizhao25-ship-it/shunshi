"""危机热线只有一个来源：app/safety/config.py。

依据：国家卫健委 2024-12-06 通知，2025-05-01 前全国开通统一心理援助热线 12356
（https://www.gov.cn/zhengce/zhengceku/202412/content_6994470.htm）；紧急危险时 120 / 110。
400-161-9995 是「希望24热线」，不是「全国心理援助热线」，以前几处把它标错了；
另有 010-58951332 / 010-82951332 两个互相矛盾的北京号码、台湾号码和美国的 988/911。
"""

import pathlib
import re

from fastapi.testclient import TestClient

from app.safety.config import (
    CRISIS_EMERGENCY_NUMBERS,
    CRISIS_HOTLINE,
    CRISIS_HOTLINE_NAME,
    SAFETY_CONFIG,
)

APP_DIR = pathlib.Path(__file__).resolve().parent.parent / "app"
CONFIG_FILE = APP_DIR / "safety" / "config.py"
TEXT_SUFFIXES = {".py", ".json", ".md", ".html", ".txt", ".yaml", ".yml"}
# 热线样式的号码：400/800 开头的客服热线、带区号的座机
PHONE_LIKE = re.compile(r"(?<!\d)(?:400|800)-?\d{3}-?\d{4}(?!\d)|(?<!\d)0\d{2,3}-\d{7,8}(?!\d)")


def _app_files():
    for path in sorted(APP_DIR.rglob("*")):
        if path.is_file() and path.suffix in TEXT_SUFFIXES and "__pycache__" not in path.parts:
            yield path


def test_config_is_12356_with_120_110():
    assert CRISIS_HOTLINE == "12356"
    assert SAFETY_CONFIG["crisis_hotline_cn"] == CRISIS_HOTLINE
    assert CRISIS_EMERGENCY_NUMBERS == ("120", "110")
    assert "心理援助热线" in CRISIS_HOTLINE_NAME and "400" not in CRISIS_HOTLINE_NAME


def test_scan_can_fail():
    assert PHONE_LIKE.search("全国心理援助热线：400-161-9995")
    assert PHONE_LIKE.search("北京心理危机研究与干预中心：010-82951332")
    assert not PHONE_LIKE.search("拨打 12356，或 120、110")


def test_no_other_hotline_numbers_anywhere_in_backend():
    hits = []
    for path in _app_files():
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if PHONE_LIKE.search(line) or "4001619995" in line:
                hits.append(f"{path.relative_to(APP_DIR)}:{number}: {line.strip()[:80]}")
    assert not hits, "后端还有别的热线号码：\n" + "\n".join(hits)


def test_12356_is_written_only_in_safety_config():
    hits = [
        str(path.relative_to(APP_DIR))
        for path in _app_files()
        if path != CONFIG_FILE
        # 资料库条目是经审核的内容数据（不是代码）：其免责声明里的热线号码随内容保存，
        # 不在这里强制走 config；代码文件仍然必须引用 app/safety/config.py。
        and path.relative_to(APP_DIR).parts[:2] != ("library", "data")
        and CRISIS_HOTLINE in path.read_text(encoding="utf-8", errors="ignore")
    ]
    assert not hits, f"这些文件自己写死了 12356，应改为引用 app/safety/config.py：{hits}"


def test_every_crisis_text_carries_12356():
    from app.core.safety_filter import CRISIS_RESPONSE
    from app.prompts.store import PRESET_PROMPTS
    from app.routers.chat import DISTRESS_HELP_SUFFIX
    from app.safety.guard import CRISIS_RESPONSE_CN, CRISIS_RESPONSE_EN, DEPENDENCY_SUFFIX_CN
    from app.services.age_policy import MINOR_RULES

    texts = {
        "core.safety_filter.CRISIS_RESPONSE": CRISIS_RESPONSE,
        "prompts.chat.crisis_response": PRESET_PROMPTS["chat.crisis_response"]["content"],
        "routers.chat.DISTRESS_HELP_SUFFIX": DISTRESS_HELP_SUFFIX,
        "safety.guard.CRISIS_RESPONSE_CN": CRISIS_RESPONSE_CN,
        # 国内版用户用英文提问时也在国内：不能给美国的 988/911
        "safety.guard.CRISIS_RESPONSE_EN": CRISIS_RESPONSE_EN,
        "safety.guard.DEPENDENCY_SUFFIX_CN": DEPENDENCY_SUFFIX_CN,
        "age_policy.MINOR_RULES": MINOR_RULES,
    }
    for name, text in texts.items():
        assert CRISIS_HOTLINE in text, name
        assert "988" not in text and "911" not in text, name


def test_mood_first_aid_crisis_card_uses_12356():
    from app.skills.core_skills import crisis_card_steps, crisis_reply_text

    assert CRISIS_HOTLINE in crisis_reply_text()
    assert any(CRISIS_HOTLINE in step for step in crisis_card_steps())


def test_crisis_resources_api_lists_only_12356_and_emergency():
    from fastapi import FastAPI

    from app.router.mental_wellness import router

    app = FastAPI()
    app.include_router(router)
    data = TestClient(app).get("/api/v1/mental/crisis-resources").json()["data"]
    china = [r for r in data["resources"] if r["region"] == "中国"]
    assert [r["phone"] for r in china] == [CRISIS_HOTLINE, "120", "110"]
    assert china[0]["organization"] == CRISIS_HOTLINE_NAME
    assert CRISIS_HOTLINE in data["crisis_hotlines"]["china"]
    assert "400-161" not in str(data) and "010-" not in str(data)


def test_domestic_flutter_clients_do_not_carry_the_wrong_hotline():
    """同一仓库里的国内客户端（android-cn / ios-cn）也不能再写 400-161-9995 或北京中心的旧号码。"""
    repo = APP_DIR.parent.parent
    hits = []
    for client_dir in ("android-cn", "ios-cn"):
        for sub in ("lib", "test"):
            root = repo / client_dir / sub
            for path in sorted(root.rglob("*.dart")) if root.exists() else []:
                text = path.read_text(encoding="utf-8", errors="ignore")
                if PHONE_LIKE.search(text) or "4001619995" in text:
                    hits.append(str(path.relative_to(repo)))
    assert not hits, f"客户端还有旧热线号码：{hits}"
