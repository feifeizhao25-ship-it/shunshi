"""0S3：顺时不是医疗/保健产品。后端下发给用户的文案不得含功效化用语。
wellness_myth.py 是“辟谣”内容（解释为什么“排毒”是误区），豁免。"""
import pathlib
import re

BANNED = re.compile("排毒|利尿|消肿|增强免疫")
APP = pathlib.Path(__file__).resolve().parents[1] / "app"


def test_backend_copy_has_no_banned_medical_words():
    hits = []
    for f in APP.rglob("*.py"):
        if f.name == "wellness_myth.py":
            continue
        for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            if BANNED.search(line):
                hits.append(f"{f.relative_to(APP)}:{i}")
    assert hits == [], "\n".join(hits)
