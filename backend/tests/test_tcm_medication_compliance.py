"""批1合规: 中成药接口不得下发剂量/频次/疗程/长期服用, 只作一般科普+遵医嘱."""
import json, re
from app.router.tcm_medication import MEDICINES

BANNED = re.compile(r"每次\s*\d|一日\s*\d|一天\s*\d|可长期服用|长期服用|dosage|duration_typical|\d+\s*-\s*\d+\s*g|温开水送服")

def test_medicines_have_no_dosage_or_course():
    blob = json.dumps(MEDICINES, ensure_ascii=False)
    assert not BANNED.search(blob), BANNED.search(blob)
    for med in MEDICINES.values():
        assert "general_info" in med and "不构成" in med["general_info"]
        assert "遵医嘱" in med["caution"] or "咨询医师" in med["caution"]
        assert "dosage_note" not in med and "duration_typical" not in med

def test_output_efficacy_filter_blocks_claims():
    from app.safety.guard import safety_guard
    for text in ["常喝这个可以增强免疫力。", "有助于排毒消肿。", "能提高免疫功能，利尿。", "这个可以长期服用。"]:
        r = safety_guard.check_output(text, {"user_id": "test"})
        assert r.flag == "output_violation", text
    ok = safety_guard.check_output("早睡早起、规律作息对精神状态有帮助。", {"user_id": "test"})
    assert ok.flag != "output_violation"
