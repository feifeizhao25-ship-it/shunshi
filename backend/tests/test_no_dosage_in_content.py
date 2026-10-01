"""顺时不做处方：中药材、辟谣等内容接口不能给出用量、剂量与服法。

依据「四项目-19项要求-第三版批注」：健康心理类只做一般性信息与就医引导，不做诊断、不做处方。
"""
import re

from app.router import herbal_knowledge, wellness_myth

# “6-12g”“每日 6–15 克”“一日 2-3 次”“每次 2g”一类
DOSE = re.compile(r"\d+\s*[-–~至]\s*\d+\s*(g|克|ml|毫升|枚|片|粒)|每(次|日|天)\s*\d+|一日\s*\d+")


def test_herb_entries_have_no_dosage():
    assert len(herbal_knowledge.HERBS) >= 7
    for hid, herb in herbal_knowledge.HERBS.items():
        assert "dosage" not in herb, hid
        assert herb.get("usage_notice"), f"{hid} 缺少「不是处方」声明"
        for k, v in herb.items():
            assert not DOSE.search(str(v)), f"{hid}.{k} 出现用量：{v}"


def test_myth_entries_have_no_dosage():
    # 只查中药类条目：饮水量、运动时长之类的一般生活建议不在此列
    herbal = {i: m for i, m in wellness_myth.MYTHS.items() if "中药" in m.get("category", "") or "中药" in m.get("tags", [])}
    assert herbal, "没找到中药类条目，检查条件写错了"
    for mid, m in herbal.items():
        for k, v in m.items():
            assert not DOSE.search(str(v)), f"{mid}.{k} 出现用量：{v}"


def test_the_scan_can_fail():
    assert DOSE.search("6-12g，煎服") and DOSE.search("每日用量6-15g") and DOSE.search("一日 2-3 次")


# ── 全部已挂载路由模块的内容数据：不得出现方剂式的处方语言 ───────────────────
import pathlib
import re

from app.main import PENDING_REVIEW_MODULES

ROUTER_DIR = pathlib.Path(__file__).resolve().parent.parent / "app" / "router"
# 方剂配伍术语（君臣佐使）、中药服法（煎服/水煎/冲服/送服）、
# 「某某汤/散是……处方，可长期服用」「需医嘱」式的用药指引、药材+克数的用量
PRESCRIPTION_LANGUAGE = re.compile(
    r"[君臣佐使]药|水煎|煎服|冲服|(?<!推)送服|经典的.{0,6}处方|处方.{0,6}可长期服用|可长期服用"
    r"|(黄芪|当归|人参|党参|白术|川芎|熟地|附子|麻黄)\s*\d+\s*(g|克)"
)


def _mounted_router_files():
    return [p for p in sorted(ROUTER_DIR.glob("*.py")) if p.stem not in PENDING_REVIEW_MODULES]


def test_scan_sees_the_router_modules_and_can_fail():
    assert len(_mounted_router_files()) > 100
    assert PRESCRIPTION_LANGUAGE.search("君药，清肝明目") and PRESCRIPTION_LANGUAGE.search("水煎30分钟饮用")
    assert PRESCRIPTION_LANGUAGE.search("是经典的补肺卫处方，可长期服用") and PRESCRIPTION_LANGUAGE.search("黄芪15g")


def test_no_mounted_module_contains_prescription_language():
    hits = []
    for path in _mounted_router_files():
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            if PRESCRIPTION_LANGUAGE.search(line):
                hits.append(f"{path.name}:{number}: {line.strip()[:70]}")
    assert not hits, "出现方剂/服法/用量式的处方语言：\n" + "\n".join(hits)


def test_every_tea_formula_says_it_is_not_a_prescription():
    from app.router import tea

    assert len(tea.TEA_FORMULAS) >= 7
    assert all(t.get("usage_notice") and "不是处方" in t["usage_notice"] for t in tea.TEA_FORMULAS)
