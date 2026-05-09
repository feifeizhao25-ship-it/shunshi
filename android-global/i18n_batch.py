#!/usr/bin/env python3
"""Batch i18n processor for ShunShi Global Flutter app."""
import re, os, sys, json
from pathlib import Path

BASE = Path.home() / "Documents/Shunshi/android-global"
PAGES = BASE / "lib/presentation/pages"
LOC_FILE = BASE / "lib/core/theme/app_localizations.dart"

# Already i18n'd files (from previous batch)
DONE = {
    "about/about_page.dart", "chat/chat_page.dart", "checkin/daily_checkin_v2.dart",
    "family/family_page_v2.dart", "favorites/favorites_page.dart", "feedback/feedback_page.dart",
    "home/ultimate_home_page.dart", "login/login_page.dart", "meditation/meditation_focus_page.dart",
    "notifications/notifications_page.dart", "onboarding/onboarding_page.dart",
    "profile/profile_page_v2.dart", "search/global_search_page.dart", "settings/settings_page_v2.dart",
    "solar/solar_detail_page.dart", "solar/solar_term_page_v2.dart", "subscription/subscription_page_v2.dart",
    "wellness/constitution_page.dart", "wellness/exercise_page.dart", "wellness/wellness_home_page.dart",
}

# Skip non-UI files
SKIP = {"chat_models.dart", "solar_term_data.dart", "constitution_data.dart", "home_page_intl.dart"}

def find_hardcoded_strings(content):
    """Find hardcoded English strings in Text(), title, hint, label, etc."""
    strings = []
    # Pattern: Text('...') or Text("...") - capture the string
    patterns = [
        r"Text\(\s*'([^']{2,80})'\s*[\),]",
        r'Text\(\s*"([^"]{2,80})"\s*[\),]',
        r"title:\s*'([^']{2,80})'",
        r'title:\s*"([^"]{2,80})"',
        r"hint:\s*'([^']{2,80})'",
        r'hint:\s*"([^"]{2,80})"',
        r"label:\s*'([^']{2,80})'",
        r'label:\s*"([^"]{2,80})"',
        r"AppBar.*title:\s*Text\(\s*'([^']{2,80})'",
    ]
    seen = set()
    for pat in patterns:
        for m in re.finditer(pat, content):
            s = m.group(1).strip()
            # Filter out non-translatable strings
            if s in seen: continue
            if re.match(r'^[\d\s\-\.:]+$', s): continue  # numbers only
            if s.startswith('${') or s.startswith('{'): continue  # interpolation
            if re.match(r'^[A-Z_]+$', s): continue  # constants like SEASONS
            if len(s) < 2: continue
            if not re.search(r'[a-zA-Z]', s): continue  # no letters
            seen.add(s)
            strings.append(s)
    return strings

def make_key(s):
    """Convert a string to a snake_case i18n key."""
    # Remove special chars, lowercase, replace spaces with underscores
    k = re.sub(r"[^\w\s]", '', s.lower()).strip()
    k = re.sub(r"\s+", '_', k)
    k = k[:40]
    # Remove trailing/leading underscores
    k = k.strip('_')
    return k

def main():
    # Read current localization file
    loc_content = LOC_FILE.read_text()
    
    # Find the end of each locale map (last entry before closing })
    # Extract existing keys
    existing_keys = set(re.findall(r"'([a-z_0-9]+)'\s*:", loc_content))
    
    # Find files to process
    files_to_process = []
    for dart_file in sorted(PAGES.rglob("*.dart")):
        rel = dart_file.relative_to(PAGES)
        rel_str = str(rel)
        if rel_str in DONE: continue
        if dart_file.name in SKIP: continue
        content = dart_file.read_text()
        if "AppLocalizations" in content: continue
        strings = find_hardcoded_strings(content)
        if strings:
            files_to_process.append((dart_file, strings))
    
    print(f"Found {len(files_to_process)} files to process")
    
    # Generate new keys
    new_keys = {}  # key -> (en, ja, zh)
    for dart_file, strings in files_to_process:
        for s in strings:
            base_key = make_key(s)
            key = base_key
            suffix = 2
            while key in existing_keys:
                key = f"{base_key}_{suffix}"
                suffix += 1
            existing_keys.add(key)
            new_keys[key] = s
    
    print(f"Generated {len(new_keys)} new keys")
    
    # Print summary for review
    for dart_file, strings in files_to_process[:50]:
        print(f"\n{dart_file.relative_to(PAGES)}:")
        for s in strings:
            key = make_key(s)
            print(f"  '{s}' -> {key}")
    
    # Write JSON for later use
    out = {
        "new_keys": {k: v for k, v in new_keys.items()},
        "files": [(str(f.relative_to(PAGES)), s) for f, s in files_to_process]
    }
    (BASE / "i18n_new_keys.json").write_text(json.dumps(out, indent=2, ensure_ascii=False))
    print(f"\nWrote i18n_new_keys.json")

if __name__ == "__main__":
    main()
