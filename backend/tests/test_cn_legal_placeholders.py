"""国内版用户可见法律页不能再出现内部备注和占位联系方式。"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SURFACES = (ROOT / "android-cn" / "lib", ROOT / "ios-cn" / "lib")
BANNED = ("待公司开通", "律师定稿", "稿子", "待填写", "备案材料里填写")


def test_domestic_ui_has_no_legal_placeholders():
    hits = []
    for surface in SURFACES:
        for path in surface.rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            for phrase in BANNED:
                if phrase in text:
                    hits.append(f"{path.relative_to(ROOT)}: {phrase}")
    assert hits == []
