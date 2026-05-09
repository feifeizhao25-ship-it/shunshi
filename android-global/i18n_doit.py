#!/usr/bin/env python3
"""i18n batch processor - process Flutter files and add keys to localization."""
import re, os, sys, json
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

# Strings that should NOT be translated (common technical strings)
SKIP_STRINGS = {
    '', ' ', '•', '-', '·', '|', '/', ':', '...', '>>', '<<', '+', '×',
    'OK', 'GPS', 'AI', 'URL', 'HTTP', 'JSON', 'API', 'SDK', 'ID', 'VIP',
}

def make_key(english, prefix=""):
    """Convert English string to snake_case key."""
    k = english.lower().strip()
    k = re.sub(r"[^\w\s]", '', k)
    k = re.sub(r"\s+", '_', k)
    k = k.strip('_')[:45]
    if not k or not re.search(r'[a-z]', k):
        return None
    if prefix:
        k = prefix + '_' + k
    return k

def read_loc_sections():
    """Parse localization file into sections."""
    content = LOC_FILE.read_text()
    lines = content.split('\n')
    
    # Find section boundaries
    en_start = en_end = ja_start = ja_end = zh_start = zh_end = None
    prefix_start = prefix_end = None
    
    for i, line in enumerate(lines):
        if "'en': {" in line: en_start = i
        elif "'ja': {" in line: ja_start = i
        elif "'zh': {" in line: zh_start = i
        # Find the closing of each section
        if en_start and not en_end and line.strip() == '},':
            if i > en_start and (not ja_start or i < ja_start):
                en_end = i
        if ja_start and not ja_end and line.strip() == '},':
            if i > ja_start and (not zh_start or i < zh_start):
                ja_end = i
    
    # zh end is before the final };
    for i in range(len(lines)-1, -1, -1):
        if lines[i].strip() == '},':
            zh_end = i
            break
    
    return content, lines, en_start, en_end, ja_start, ja_end, zh_start, zh_end

def extract_existing_keys(lines, start, end):
    """Extract key->value from a locale section."""
    keys = {}
    for i in range(start+1, end):
        m = re.match(r"\s+'([a-z_][a-z0-9_]*)'\s*:\s*'(.+?)'\s*,?\s*$", lines[i])
        if m:
            keys[m.group(1)] = m.group(2)
    return keys

def find_translatable_strings(content, filepath):
    """Find hardcoded strings that should be i18n'd."""
    results = []  # (match_text, string_value, line_number)
    lines = content.split('\n')
    
    # Patterns to match
    patterns = [
        # Text('...') with simple strings
        (r"""Text\(\s*'([^'\n]{2,60})'\s*[,)]""", 1),
        (r"""Text\(\s*"([^"\n]{2,60})"\s*[,)]""", 1),
        # title: '...'
        (r"""title:\s*'([^'\n]{2,60})'""", 1),
        # hint: '...'
        (r"""hint:\s*'([^'\n]{2,60})'""", 1),
        # label: '...'
        (r"""label:\s*'([^'\n]{2,60})'""", 1),
    ]
    
    seen = set()
    for i, line in enumerate(lines, 1):
        # Skip import lines, comments, and lines already using t(
        if 'import ' in line or line.strip().startswith('//') or '.t(' in line or 'AppLocalizations' in line:
            continue
        for pat, grp in patterns:
            for m in re.finditer(pat, line):
                s = m.group(grp)
                if s in seen or s in SKIP_STRINGS:
                    continue
                # Filter: must contain letters, not be only numbers/symbols
                if not re.search(r'[a-zA-Z]{2,}', s):
                    continue
                # Skip interpolation strings (complex)
                if '${' in s or '$' in s:
                    continue
                # Skip all-caps constants (like SEASONS, but not short phrases)
                if s.isupper() and len(s.split()) <= 2:
                    continue
                seen.add(s)
                results.append((m.group(0), s, i))
    
    return results

def main():
    content, lines, en_start, en_end, ja_start, ja_end, zh_start, zh_end = read_loc_sections()
    
    en_keys = extract_existing_keys(lines, en_start, en_end)
    ja_keys = extract_existing_keys(lines, ja_start, ja_end)
    zh_keys = extract_existing_keys(lines, zh_start, zh_end)
    all_existing = set(en_keys.keys()) | set(ja_keys.keys()) | set(zh_keys.keys())
    
    # Build reverse map: english value -> key for reuse
    val_to_key = {}
    for k, v in en_keys.items():
        val_to_key[v] = k
    
    # Collect all files to process
    files = []
    for dart_file in sorted(PAGES.rglob("*.dart")):
        rel = str(dart_file.relative_to(PAGES))
        if rel in DONE_FILES or dart_file.name in SKIP_FILES:
            continue
        fc = dart_file.read_text()
        if "AppLocalizations" in fc:
            continue
        strings = find_translatable_strings(fc, rel)
        if strings:
            files.append((dart_file, fc, strings))
    
    print(f"Processing {len(files)} files")
    
    # New keys to add
    new_en = {}
    new_ja = {}
    new_zh = {}
    file_edits = []  # (filepath, replacements: [(old, new)])
    
    key_counter = {}
    
    for dart_file, fc, strings in files:
        rel = str(dart_file.relative_to(PAGES))
        # Derive prefix from directory
        parts = Path(rel).parts
        prefix = parts[0] if parts[0] != '.' else ''
        # Clean prefix
        prefix = re.sub(r'[^a-z]', '', prefix)[:15]
        
        replacements = []
        file_new_keys = set()
        
        for match_text, string_val, line_num in strings:
            # Check if already have a key for this value
            if string_val in val_to_key:
                key = val_to_key[string_val]
            else:
                # Create new key
                base = make_key(string_val, prefix)
                if not base:
                    continue
                key = base
                suffix = 2
                while key in all_existing or key in file_new_keys:
                    key = f"{base}_{suffix}"
                    suffix += 1
                file_new_keys.add(key)
                all_existing.add(key)
                
                # Add to new keys
                new_en[key] = string_val
                # For ja, use English as placeholder (needs human translation)
                new_ja[key] = string_val
                # For zh, we can provide rough translations for common patterns
                new_zh[key] = string_val  # placeholder
                val_to_key[string_val] = key
            
            # Build replacement
            # Replace the string literal in the match with t.t('key')
            old = match_text
            # Find the string part and replace it
            if "Text(" in match_text:
                new = match_text.replace(f"'{string_val}'", f"t.t('{key}')").replace(f'"{string_val}"', f"t.t('{key}')")
            elif "title:" in match_text:
                new = match_text.replace(f"'{string_val}'", f"t.t('{key}')")
            elif "hint:" in match_text:
                new = match_text.replace(f"'{string_val}'", f"t.t('{key}')")
            elif "label:" in match_text:
                new = match_text.replace(f"'{string_val}'", f"t.t('{key}')")
            else:
                new = match_text.replace(f"'{string_val}'", f"t.t('{key}')")
            
            replacements.append((old, new))
        
        if replacements:
            file_edits.append((dart_file, fc, replacements))
    
    print(f"Total new keys: {len(new_en)}")
    
    # Now apply edits
    import_added_count = 0
    
    for dart_file, fc, replacements in file_edits:
        new_content = fc
        for old, new in replacements:
            if old in new_content:
                new_content = new_content.replace(old, new, 1)
            else:
                print(f"  WARNING: could not find '{old[:50]}' in {dart_file.name}")
        
        # Add import if needed
        if "t.t(" in new_content and "AppLocalizations" not in new_content:
            import_line = "import '../../../core/theme/app_localizations.dart';\n"
            # Find last import line
            last_import = 0
            for i, line in enumerate(new_content.split('\n')):
                if line.startswith('import '):
                    last_import = i
            lines_list = new_content.split('\n')
            lines_list.insert(last_import + 1, import_line.rstrip())
            new_content = '\n'.join(lines_list)
            import_added_count += 1
        
        # Add `final t = AppLocalizations.of(context);` in build method if not present
        if "t.t(" in new_content and "final t = " not in new_content and "AppLocalizations.of(context)" not in new_content:
            # Find Widget build method and add after opening brace
            new_content = re.sub(
                r'(Widget build\(BuildContext context\) \{\n)',
                r"\1    final t = AppLocalizations.of(context);\n",
                new_content,
                count=1
            )
        
        dart_file.write_text(new_content)
        print(f"  Edited: {dart_file.relative_to(PAGES)} ({len(replacements)} strings)")
    
    print(f"\nEdited {len(file_edits)} files, added {import_added_count} imports")
    
    # Now add new keys to localization file
    if new_en:
        # Re-read the file
        content, lines, en_start, en_end, ja_start, ja_end, zh_start, zh_end = read_loc_sections()
        
        # Format new key entries
        def format_keys(key_dict):
            return '\n'.join(f"      '{k}': '{v}'," for k, v in sorted(key_dict.items()))
        
        # Insert into en section (before closing })
        en_insert = format_keys(new_en)
        lines.insert(en_end, en_insert)
        # Adjust offsets
        ja_start += len(new_en)
        ja_end += len(new_en)
        zh_start += len(new_en)
        zh_end += len(new_en)
        
        # Insert into ja section
        ja_insert = format_keys(new_ja)
        lines.insert(ja_end, ja_insert)
        zh_start += len(new_ja)
        zh_end += len(new_ja)
        
        # Insert into zh section
        zh_insert = format_keys(new_zh)
        lines.insert(zh_end, zh_insert)
        
        LOC_FILE.write_text('\n'.join(lines))
        print(f"Added {len(new_en)} keys to localization file")
    
    # Print new keys for zh translation reference
    if new_zh:
        print("\n=== New keys (need zh translation) ===")
        for k in sorted(new_zh.keys()):
            print(f"  '{k}': '{new_en[k]}'")

if __name__ == "__main__":
    main()
