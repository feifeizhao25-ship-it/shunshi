"""国内版和国际版的求助号码不能串（2026-10-31 评审：助手代用户决定，待运营复核）。

规则：
- 国际版（ios-global / android-global）不能出现中国号码（400/800 热线、12356、12320）或「120 急救」；
  988 只能写在标了 US / Canada 的行里，741741 只能标 US only；英国用 Samaritans 116 123，
  不能把 NHS 111（非紧急咨询）当危机热线；澳大利亚 13 11 14 是 Lifeline，不是 Beyond Blue。
- 国内版（ios-cn / android-cn）不能出现 988 / 741741 / 12320，也不能出现国际号码。
- 后端 safety 配置里不能有 12320。
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
CHINA_NUMBER = re.compile(r"(?<!\d)(?:400|800)-?\d{3}-?\d{4}(?!\d)|(?<!\d)0\d{2,3}-\d{7,8}(?!\d)|(?<!\d)1235[56](?!\d)|(?<!\d)12320(?!\d)")
EMERGENCY_120 = re.compile(r"(?:emergency|Emergency|911 or)[^\n]{0,30}(?<!\d)120(?!\d)|(?<!\d)120(?!\d)[^\n]{0,12}(?:急救|emergency)")
US_MARK = re.compile(r"\bUS\b|U\.S\.|Canada|988lifeline|988\.ca|9-8-8")


def _lines(edition: str):
    for path in sorted((ROOT / edition / "lib").rglob("*.dart")):
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            yield f"{path.relative_to(ROOT)}:{number}", line


def test_scan_can_fail():
    assert CHINA_NUMBER.search("24h Mental Health Helpline: 400-161-9995")
    assert CHINA_NUMBER.search("call 12320")
    assert EMERGENCY_120.search("• Emergency: 120")
    assert EMERGENCY_120.search("拨打 120 急救电话")
    assert not EMERGENCY_120.search("height: 120")


def test_international_clients_carry_no_china_numbers_or_120():
    hits = []
    for edition in ("ios-global", "android-global"):
        for where, line in _lines(edition):
            if CHINA_NUMBER.search(line) or EMERGENCY_120.search(line):
                hits.append(f"{where}: {line.strip()[:90]}")
    assert not hits, "国际版里还有中国号码或 120：\n" + "\n".join(hits)


def test_988_is_scoped_to_us_canada_and_741741_to_us():
    hits = []
    for edition in ("ios-global", "android-global"):
        for where, line in _lines(edition):
            if re.search(r"(?<!\d)988(?!\d)", line) and not US_MARK.search(line) and "Suicide & Crisis" not in line:
                hits.append(f"{where}: {line.strip()[:90]}")
            if "741741" in line and not re.search(r"\bUS\b", line):
                hits.append(f"{where}: {line.strip()[:90]}")
    assert not hits, "988 / 741741 没有标注适用国家：\n" + "\n".join(hits)


def test_uk_and_australia_labels_are_correct():
    hits = []
    for edition in ("ios-global", "android-global"):
        for where, line in _lines(edition):
            if "NHS Mental Health" in line or re.search(r"13 11 14\s*Beyond Blue", line):
                hits.append(f"{where}: {line.strip()[:90]}")
    assert not hits, "UK 应写 Samaritans 116 123；AU 13 11 14 是 Lifeline：\n" + "\n".join(hits)


def test_domestic_clients_do_not_carry_overseas_or_non_psych_numbers():
    hits = []
    for edition in ("ios-cn", "android-cn"):
        for where, line in _lines(edition):
            if re.search(r"(?<!\d)(?:988|741741|12320)(?!\d)", line) and "solar" not in where:
                hits.append(f"{where}: {line.strip()[:90]}")
    assert not hits, "国内版出现国际号码或 12320：\n" + "\n".join(hits)


def test_backend_never_uses_12320_as_a_psychological_line():
    for path in (ROOT / "backend" / "app").rglob("*.py"):
        assert "12320" not in path.read_text(encoding="utf-8", errors="ignore"), path
