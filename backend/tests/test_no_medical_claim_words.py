"""0S3：顺时不是医疗/保健产品。后端下发给用户的文案不得含功效化用语。
wellness_myth.py 是“辟谣”内容（解释为什么“排毒”是误区），豁免。
safety/config.py 与 safety/efficacy.py 是过滤规则本身，豁免。
冷启动脚本和 seed_db.py 会写入内容库，一并扫描。"""
import pathlib
import re

BANNED = re.compile("排毒|利尿|消肿|增强免疫")
BACKEND = pathlib.Path(__file__).resolve().parents[1]
APP = BACKEND / "app"
EXTRA = [BACKEND / "scripts", BACKEND / "seed_db.py"]
EXEMPT = {"wellness_myth.py", "config.py", "efficacy.py"}


def _hits(root: pathlib.Path) -> list[str]:
    files = [root] if root.is_file() else list(root.rglob("*.py"))
    hits = []
    for f in files:
        if f.name in EXEMPT and "safety" in f.parts:
            continue
        if f.name == "wellness_myth.py":
            continue
        for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            if BANNED.search(line):
                hits.append(f"{f.relative_to(BACKEND)}:{i}")
    return hits


def test_backend_copy_has_no_banned_medical_words():
    hits = _hits(APP)
    for extra in EXTRA:
        hits.extend(_hits(extra))
    assert hits == [], "\n".join(hits)
