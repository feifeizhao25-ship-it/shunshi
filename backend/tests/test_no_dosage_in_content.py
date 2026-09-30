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
