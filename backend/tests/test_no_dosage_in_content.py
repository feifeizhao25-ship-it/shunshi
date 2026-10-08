"""顺时不做处方：中药材、辟谣等内容接口不能给出用量、剂量与服法。

依据「四项目-19项要求-第三版批注」：健康心理类只做一般性信息与就医引导，不做诊断、不做处方。
"""
import json
import re

import pytest

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


# ── 中成药 / 经典方剂名：不论在哪个模块、以什么字段出现，都不能当建议给出 ──────────────
# 补丁 13 的正则抓不到成药名（「玉屏风散…可长期调理」「六味地黄丸（代表方）」照样上线）。
# 这里分两类：带成药剂型后缀的名字（丸/颗粒/胶囊/口服液/冲剂/合剂），以及常见经典方名（散/汤/饮）。
# 「肉丸、鱼丸、丸子」是食物，排除；「麻沸散」是医学史典故，不在名单里。
APP_DIR = ROUTER_DIR.parent
PATENT_MEDICINE = re.compile(
    r"[一-鿿]{2,6}(?<![肉鱼虾睾])丸(?!子)"
    r"|[一-鿿]{2,6}(?:颗粒|胶囊|口服液|冲剂|合剂)"
    r"|玉屏风|逍遥散|逍遥丸|参苓白术|[四六]君子汤|四物汤|八珍汤|十全大补|当归补血汤|生化汤|[黄小]芪?建中汤"
    r"|酸枣仁汤|沙参麦冬汤|龙胆泻肝|天麻钩藤饮|补中益气[汤丸]|归脾[汤丸]|温胆汤|甘麦大枣汤|桂枝汤|麻黄汤"
    r"|小柴胡|银翘散|藿香正气|血府逐瘀|六味地黄|金匮肾气|知柏地黄|杞菊地黄|[左右]归[丸饮]|二陈[汤丸]"
    r"|理中[汤丸]|附子理中|旋覆代赭|半夏泻心|平胃散|五苓散|麻子仁|五子衍宗|板蓝根|连花清瘟|安宫牛黄"
    r"|可长期调理|代表方|核心方剂"
)
# 这些文件里的成药名是「禁止/拦截」名单，不是推荐
PATENT_SCAN_EXCLUDED = {
    APP_DIR / "safety" / "config.py",
}
CONTENT_SUFFIXES = {".py", ".json", ".md", ".html", ".txt", ".yaml", ".yml"}


def _content_files():
    pending = {ROUTER_DIR / f"{name}.py" for name in PENDING_REVIEW_MODULES}
    for path in sorted(APP_DIR.rglob("*")):
        if (
            path.is_file()
            and path.suffix in CONTENT_SUFFIXES
            and "__pycache__" not in path.parts
            and path not in pending
            and path not in PATENT_SCAN_EXCLUDED
        ):
            yield path


def test_patent_medicine_scan_can_fail():
    for bad in (
        "玉屏风散（益气固表）", "六味地黄丸（滋阴）", "金匮肾气丸（代表方）", "左归丸", "麻子仁丸（气虚型）",
        "理中丸（人参、白术）", "逍遥散", "五子衍宗丸", "板蓝根颗粒", "四君子汤可长期温和补气",
        "可用生化汤促进恶露排出", "天麻钩藤饮", "黄芪建中汤", "某某胶囊", "某某口服液", "可长期调理",
    ):
        assert PATENT_MEDICINE.search(bad), bad
    for ok in ("牛肉丸子汤", "鱼丸", "红枣枸杞粥", "华佗首创麻沸散", "当归生姜羊肉汤", "补中益气、健脾和胃"):
        assert not PATENT_MEDICINE.search(ok), ok
    assert len(list(_content_files())) > 300


def test_no_patent_medicine_or_formula_names_anywhere():
    hits = []
    for path in _content_files():
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if path.suffix == ".py" and line.lstrip().startswith("#"):
                continue
            match = PATENT_MEDICINE.search(line)
            if match:
                hits.append(f"{path.relative_to(APP_DIR)}:{number}: 「{match.group(0)}」 {line.strip()[:60]}")
    assert not hits, "出现中成药/方剂名推荐（改成生活方式建议 + 就医提示）：\n" + "\n".join(hits)


# 原来给出中成药/方剂的公开接口：返回里不能再有，且要带「用药请遵医嘱」式的就医提示
FORMER_FORMULA_ENDPOINTS = [
    "/api/v1/child-wellness/common-issues/night_sweats",
    "/api/v1/kidney-care/deficiency-types",
    "/api/v1/kidney-care/deficiency-types/kidney_yin",
    "/api/v1/kidney-care/deficiency-types/kidney_yang",
    "/api/v1/kidney-care/deficiency-types/kidney_jing",
    "/api/v1/youth/conditions/recurrent_cold",
    "/api/v1/senior/conditions/constipation",
    "/api/v1/allergy/prevention-plan",
    "/api/v1/hair-care/conditions/hair_loss",
    "/api/v1/maternity/postpartum/natural",
    "/api/v1/maternity/postpartum/cesarean",
] + [
    f"/api/v1/chronic/conditions/{cid}"
    for cid in ("chronic_fatigue", "insomnia", "chronic_gastritis", "cervical_spondylosis", "chronic_rhinitis",
                "mild_depression_tendency", "pre_diabetes", "hypertension_tendency")
]


@pytest.mark.parametrize("path", FORMER_FORMULA_ENDPOINTS)
def test_former_formula_endpoints_give_lifestyle_advice_only(client, path):
    response = client.get(path)
    assert response.status_code == 200, (path, response.text[:200])
    text = json.dumps(response.json(), ensure_ascii=False)
    match = PATENT_MEDICINE.search(text)
    assert not match, f"{path} 仍返回「{match.group(0)}」"
    assert "遵医嘱" in text or "就医" in text, f"{path} 缺少就医/遵医嘱提示"


def test_kidney_endpoint_does_not_conclude_a_syndrome_type(client):
    """「肾虚类型辨识」不再按症状给出「肾阴虚/肾阳虚/肾精不足」的证型结论，也不再给药。"""
    for path in ("/api/v1/kidney-care/deficiency-types", "/api/v1/kidney-care/deficiency-types/kidney_yang"):
        data = client.get(path).json()["data"]
        text = json.dumps(data, ensure_ascii=False)
        for word in ("肾阴虚", "肾阳虚", "肾精不足", "辨识", "证型：", "附子", "肉桂", "山茱萸"):
            assert word not in text, (path, word)
        assert "不判断" in text


# ── 药材科普不能写「主治」病症 ────────────────────────────────────────────
DISEASE_TERMS = ("月经不调", "闭经", "痛经", "便秘", "脱肛", "喘咳", "咽喉肿痛", "泻痢", "经闭", "便溏", "体虚欲脱", "脏躁")


def test_herb_entries_use_plain_traditional_wording_not_indications():
    for hid, herb in herbal_knowledge.HERBS.items():
        assert "indications" not in herb, f"{hid} 仍返回主治（indications）"
        assert "传统上" in herb["traditional_use"] and "科普" in herb["traditional_use"], hid
        assert herb["plain_note"], hid
        text = json.dumps(herb, ensure_ascii=False)
        hits = [w for w in DISEASE_TERMS if w in text]
        assert not hits, f"{hid} 出现疾病治疗用语：{hits}"
