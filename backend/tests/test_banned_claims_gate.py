"""REQ-D4S-03 / B2-D4-SS-12-1: the claim gate fails on a planted token and passes the tree."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "verify_banned_claims.py"


def test_cn_dart_copy_has_no_banned_claims():
    proc = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_planted_banned_token_fails_the_gate(tmp_path):
    planted = tmp_path / "planted.dart"
    planted.write_text("const label = '本周祛湿调理方案';\n", encoding="utf-8")
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "--extra", str(planted)],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 1
    assert "祛湿" in proc.stdout


def test_onboarding_and_quiz_use_seasonal_habit_copy():
    onboarding = (ROOT / "android-cn/lib/presentation/pages/onboarding/onboarding_page.dart").read_text(encoding="utf-8")
    ios = (ROOT / "ios-cn/lib/presentation/pages/onboarding/onboarding_page.dart").read_text(encoding="utf-8")
    login = (ROOT / "android-cn/lib/presentation/pages/login/login_page.dart").read_text(encoding="utf-8")
    quiz = (ROOT / "android-cn/lib/presentation/pages/wellness/constitution_page.dart").read_text(encoding="utf-8")
    assert "养生顾问" not in onboarding
    assert "养生顾问" not in ios
    assert "养生顾问" not in login
    assert "节气生活助手" in onboarding
    assert "节气生活习惯自测" in quiz
    assert "你的生活习惯倾向" in quiz


def test_international_constitution_routes_redirect_home():
    for rel in (
        "android-global/lib/core/router/app_router.dart",
        "ios-global/lib/core/router/app_router.dart",
    ):
        text = (ROOT / rel).read_text(encoding="utf-8")
        for path in ("/constitution'", "/constitution-test'", "/constitution-report'", "/wellness/constitution'"):
            assert path in text
        assert "ConstitutionPage()" not in text
        assert text.count("redirect: (context, state) => '/home'") >= 4
