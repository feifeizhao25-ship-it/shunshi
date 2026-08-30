#!/usr/bin/env python3
"""
Fix all .execute("SQL...) calls to use text() wrapping.
Handles both single-line and multi-line patterns, properly balancing parentheses.
Adds 'from sqlalchemy.sql import text' import where needed.
"""
import re
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent / "app"
SQL_KEYWORDS = "(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP)"

modified_files = set()

def has_text_import(content):
    return bool(re.search(r'from sqlalchemy\.(sql\s+)?import\b.*\btext\b', content))

def add_text_import(filepath, content):
    """Add import to the top of the file, after existing imports."""
    lines = content.split('\n')
    
    # Find insertion point: after last top-level import/from line
    insert_idx = 0
    in_docstring = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Track module-level docstrings
        if not in_docstring and (stripped.startswith('"""') or stripped.startswith("'''")):
            # Could be opening or one-liner
            if stripped.count('"""') >= 2 or stripped.count("'''") >= 2:
                insert_idx = i + 1
                continue
            in_docstring = True
            continue
        if in_docstring:
            if '"""' in stripped or "'''" in stripped:
                in_docstring = False
                insert_idx = i + 1
            continue
        
        if stripped.startswith('import ') or stripped.startswith('from '):
            insert_idx = i + 1
        elif stripped == '' or stripped.startswith('#'):
            if insert_idx > 0:
                insert_idx = i + 1
        elif insert_idx > 0:
            break
    
    lines.insert(insert_idx, "from sqlalchemy.sql import text")
    return '\n'.join(lines)


def find_matching_close_paren(lines, start_line_idx, start_col):
    """Find the matching close paren starting from (start_line_idx, start_col)."""
    depth = 0
    for li in range(start_line_idx, len(lines)):
        line = lines[li]
        start = start_col if li == start_line_idx else 0
        for ci in range(start, len(line)):
            ch = line[ci]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return (li, ci)
    return None


def find_closing_quote_or_triple(lines, start_line_idx, start_col, quote_char):
    """Find where the string ends. Handles triple quotes and single-line strings."""
    line = lines[start_line_idx]
    
    # Check for triple quote
    if line[start_col:start_col+3] == quote_char * 3:
        # Triple-quoted string
        search_start = start_col + 3
        for li in range(start_line_idx, len(lines)):
            l = lines[li]
            s = search_start if li == start_line_idx else 0
            pos = l.find(quote_char * 3, s)
            if pos != -1:
                return (li, pos + 2)  # end of closing triple quote
        return None
    else:
        # Single-line string
        for ci in range(start_col + 1, len(line)):
            if line[ci] == '\\' and ci + 1 < len(line):
                continue  # skip escaped char
            if line[ci] == quote_char:
                return (start_line_idx, ci)
        return None


def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    changes = 0
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Pattern 1: Single-line .execute("SQL_KEYWORD... or .execute(f"SQL_KEYWORD...
        # The entire SQL string is on one line
        matches = list(re.finditer(
            r'\.execute\(\s*(f?)(")(' + SQL_KEYWORDS + r')',
            line, re.IGNORECASE
        ))
        
        for m in reversed(matches):  # reverse to preserve positions
            f_prefix = m.group(1)
            quote = m.group(2)
            keyword = m.group(3)
            
            # Check text( is not already there
            full_match_start = m.start()
            # Look backwards from match to see if text( is before the quote
            before = line[full_match_start:m.start() + len('.execute(')]
            # Actually check if 'text(' appears between .execute( and the quote
            execute_open = line.find('(', full_match_start) + 1
            between_text = line[execute_open:m.start(2)]  # between ( and "
            if 'text(' in between_text:
                continue
            
            # Find the closing quote
            quote_start = m.start(2)
            quote_end_pos = find_closing_quote_or_triple(lines, i, quote_start, quote)
            if quote_end_pos is None:
                continue
            
            qli, qci = quote_end_pos
            
            if qli == i:
                # Same line - single line string
                # Insert "text(" before the quote, and ")" after the closing quote
                old_line = lines[i]
                
                before_quote = old_line[:quote_start]
                string_content = old_line[quote_start:qci + 1]
                after_close_quote = old_line[qci + 1:]
                
                new_line = before_quote + "text(" + string_content + ")" + after_close_quote
                lines[i] = new_line
                line = new_line  # update for subsequent matches
                changes += 1
        
        # Pattern 2: Multi-line .execute( \n ... "SQL_KEYWORD
        # .execute( at end of line, string on next line
        stripped = lines[i].rstrip()
        if re.search(r'\.execute\(\s*$', stripped):
            # Find the next non-empty line that has the SQL string
            for j in range(i + 1, min(i + 5, len(lines))):
                next_line = lines[j]
                next_stripped = next_line.strip()
                if not next_stripped:
                    continue
                
                # Check if starts with f?"SQL_KEYWORD
                m = re.match(r'^(\s*)(f?)(")(' + SQL_KEYWORDS + r')', next_line, re.IGNORECASE)
                if not m:
                    break
                
                indent = m.group(1)
                f_prefix = m.group(2)
                quote_char = m.group(3)
                
                # Check text( not already there
                if 'text(' in next_line[m.start():m.end()]:
                    break
                
                quote_start_col = m.start(3)
                
                # Find closing quote
                quote_end = find_closing_quote_or_triple(lines, j, quote_start_col, quote_char)
                if quote_end is None:
                    break
                
                qli, qci = quote_end
                
                if qli == j:
                    # String closes on same line as it starts
                    old_line = lines[j]
                    before_quote = old_line[:quote_start_col]
                    string_content = old_line[quote_start_col:qci + 1]
                    after_close = old_line[qci + 1:]
                    
                    new_line = before_quote + "text(" + string_content + ")" + after_close
                    lines[j] = new_line
                    changes += 1
                else:
                    # Multi-line string (triple quote)
                    # Insert "text(" before opening quote on line j
                    old_line = lines[j]
                    before_quote = old_line[:quote_start_col]
                    after_quote = old_line[quote_start_col:]
                    lines[j] = before_quote + "text(" + after_quote
                    
                    # Insert ")" after closing quote on line qli
                    old_close_line = lines[qli]
                    lines[qli] = old_close_line[:qci + 1] + ")" + old_close_line[qci + 1:]
                    changes += 1
                
                break
            
            # Also check for triple-quoted strings on same line as .execute(
            # Like .execute("""SELECT...)
            m2 = re.search(r'\.execute\(\s*(f?)(""")(' + SQL_KEYWORDS + r')', line, re.IGNORECASE)
            if m2:
                f_prefix = m2.group(1)
                tq_start = m2.start(2)
                
                # Check text( not already there
                between = line[m2.start():tq_start]
                if 'text(' not in between:
                    quote_end = find_closing_quote_or_triple(lines, i, tq_start, '"')
                    if quote_end:
                        qli, qci = quote_end
                        old_line = lines[i]
                        before_tq = old_line[:tq_start]
                        string_content = old_line[tq_start:qci + 1]
                        after_close = old_line[qci + 1:]
                        lines[i] = before_tq + "text(" + string_content + ")" + after_close
                        changes += 1
        
        i += 1
    
    if changes > 0:
        new_content = '\n'.join(lines)
        if not has_text_import(new_content):
            new_content = add_text_import(filepath, new_content)
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        
        modified_files.add(filepath)
        print(f"  ✓ {filepath}: {changes} fixes")
    else:
        print(f"  - {filepath}: clean")


for root, dirs, files in os.walk(BASE_DIR):
    dirs[:] = [d for d in dirs if d not in ('__pycache__', 'migrations', '.git')]
    for f in sorted(files):
        if not f.endswith('.py') or f == 'fix_text_wrapping.py':
            continue
        fix_file(os.path.join(root, f))

print(f"\n{'='*60}")
print(f"Total files modified: {len(modified_files)}")
