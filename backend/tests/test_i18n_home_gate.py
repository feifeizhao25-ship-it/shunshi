"""B2-D4-SS-4-1, B2-D4-SS-5-1, B2-D4-SS-14-1."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "verify_i18n_keys.py"


def test_i18n_gate_passes():
    proc = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_planted_missing_key_fails():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--require-key=planted_missing_key"],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 1
    assert "planted_missing_key" in proc.stdout


def test_home_columns_streak_copy_and_tokens():
    cn = (ROOT / "android-cn/lib/core/theme/app_localizations.dart").read_text(encoding="utf-8")
    assert "読み込み中" not in cn
    assert "_localizedValues['en']?[key]" in cn
    lib = (ROOT / "android-global/lib/presentation/pages/library/library_page.dart").read_text(encoding="utf-8")
    ios = (ROOT / "ios-global/lib/presentation/pages/library/library_page.dart").read_text(encoding="utf-8")
    for text in (lib, ios):
        assert "Seasonal Food" in text
        assert "Light & Sleep" in text
        assert "Body Types" not in text
    tip = (ROOT / "android-cn/lib/presentation/pages/achievement/achievement_page_v2.dart").read_text(encoding="utf-8")
    assert "本节气你做了$_checkinStreak件小事" in tip
    assert "百日功成还需" not in tip
    cn_tok = (ROOT / "android-cn/lib/core/theme/edition_tokens.dart").read_text(encoding="utf-8")
    intl_tok = (ROOT / "android-global/lib/core/theme/edition_tokens.dart").read_text(encoding="utf-8")
    assert "0xFFFDF9F4" in cn_tok
    assert "0xFFF3F6F1" in intl_tok
    assert cn_tok != intl_tok
