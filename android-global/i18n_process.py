#!/usr/bin/env python3
"""i18n processor - reads files needing i18n, outputs plan."""
import re, os, json
from pathlib import Path

BASE = Path("/Users/feifei00/Documents/Shunshi/android-global")
PAGES = BASE / "lib/presentation/pages"
LOC_FILE = BASE / "lib/core/theme/app_localizations.dart"

DONE_FILES = {
    "about/about_page.dart", "chat/chat_page.dart", "checkin/daily_checkin_v2.dart",
    "family/family_page_v2.dart", "favorites/favorites_page.dart", "feedback/feedback_page.dart",
    "home/ultimate_home_page.dart", "login/login_page.dart", "meditation/meditation_focus_page.dart",
    "notifications/notifications_page.dart", "onboarding/onboarding_page.dart",
    "profile/profile_page_v2.dart", "search/global_search_page.dart", "settings/settings_page_v2.dart",
    "solar/solar_detail_page.dart", "solar/solar_term_page_v2.dart", "subscription/subscription_page_v2.dart",
    "wellness/constitution_page.dart", "wellness/exercise_page.dart", "wellness/wellness_home_page.dart",
}

SKIP_FILES = {"chat_models.dart", "solar_term_data.dart", "constitution_data.dart", "home_page_intl.dart", "records_page.dart", "reflection_page.dart", "seasons_onboarding.dart"}

loc_content = LOC_FILE.read_text()
existing_keys = set(re.findall(r"'([a-z_][a-z0-9_]*)'\s*:", loc_content))

# Map existing English values to keys for reuse
en_map = {}
in_en = False
for line in loc_content.split('\n'):
    if "'en': {" in line:
        in_en = True
        continue
    if "'ja': {" in line:
        break
    if in_en:
        m = re.match(r"\s+'([a-z_][a-z0-9_]*)'\s*:\s*'(.+)'", line)
        if m:
            en_map[m.group(2)] = m.group(1)

print(f"Existing keys: {len(existing_keys)}, English value->key mappings: {len(en_map)}")

# Find files needing i18n
files = []
for dart_file in sorted(PAGES.rglob("*.dart")):
    rel = str(dart_file.relative_to(PAGES))
    if rel in DONE_FILES or dart_file.name in SKIP_FILES:
        continue
    content = dart_file.read_text()
    if "AppLocalizations" in content:
        continue
    # Check if has hardcoded strings in Text()
    if re.search(r"Text\(\s*['\"]", content):
        files.append(dart_file)

print(f"Files needing i18n: {len(files)}")

# Print file list for batch processing
for f in files[:60]:
    print(f.relative_to(PAGES))
