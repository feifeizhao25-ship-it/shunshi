#!/usr/bin/env python3
"""
解析顺时知识库 Markdown 文档并导入 contents 数据库
"""

import re
import sqlite3
import os
import json
from datetime import datetime

BASE = '/Users/feifei00/Documents/Shunshi'
DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'shunshi.db')

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn

def safe_insert(conn, cid, title, description, type_, category, tags, season_tag=None, location=None, effect=None, extra_fields=None):
    """安全的 INSERT OR IGNORE"""
    exists = conn.execute('SELECT id FROM contents WHERE id=?', (cid,)).fetchone()
    if exists:
        return 0
    vals = [cid, title, description, type_, category, tags, 'zh-CN', datetime.now().isoformat()]
    sql = '''INSERT OR IGNORE INTO contents 
        (id, title, description, type, category, tags, locale, created_at'''
    if season_tag:
        sql += ', season_tag'
        vals.append(season_tag)
    if location:
        sql += ', location'
        vals.append(location)
    if effect:
        sql += ', effect'
        vals.append(effect)
    if extra_fields:
        for k, v in extra_fields.items():
            sql += f', {k}'
            vals.append(v)
    sql += ') VALUES (' + ','.join(['?'] * len(vals)) + ')'
    conn.execute(sql, vals)
    return 1

def split_sections(text):
    """按 **标题：** 分割为 {标题: 内容} 字典"""
    sections = {}
    pattern = r'\*\*(.+?)\*\*\s*\n'
    splits = list(re.finditer(pattern, text))
    for i, m in enumerate(splits):
        title = m.group(1).rstrip('：:')
        start = m.end()
        end = splits[i+1].start() if i+1 < len(splits) else len(text)
        sections[title] = text[start:end].strip()
    return sections

def bullet_items(text):
    """提取 - 开头的列表项"""
    return [line.strip()[1:].strip() for line in text.split('\n') if line.strip().startswith('- ')]

SEASON_MAP = {}
for n, s in [('立春','spring'),('雨水','spring'),('惊蛰','spring'),('春分','spring'),('清明','spring'),('谷雨','spring'),
             ('立夏','summer'),('小满','summer'),('芒种','summer'),('夏至','summer'),('小暑','summer'),('大暑','summer'),
             ('立秋','autumn'),('处暑','autumn'),('白露','autumn'),('秋分','autumn'),('寒露','autumn'),('霜降','autumn'),
             ('立冬','winter'),('小雪','winter'),('大雪','winter'),('冬至','winter'),('小寒','winter'),('大寒','winter')]:
    SEASON_MAP[n] = s

SEASON_CN = {'spring':'春', 'summer':'夏', 'autumn':'秋', 'winter':'冬'}


def import_solar_terms(content):
    """导入24节气内容"""
    conn = get_db()
    count = 0
    
    # 按 #### N. 节气名 分割
    pattern = r'####\s*\d+\.\s*([^\n（]+)（([^\n）]+)）\s*\n'
    splits = list(re.finditer(pattern, content))
    
    for i, m in enumerate(splits):
        name = m.group(1).strip()
        dates = m.group(2).strip()
        start = m.end()
        end = splits[i+1].start() if i+1 < len(splits) else len(content)
        block = content[start:end]
        
        season_tag = SEASON_MAP.get(name, 'spring')
        sc = SEASON_CN.get(season_tag, '春')
        sections = split_sections(block)
        
        # 饮食建议
        diet = sections.get('饮食建议', '')
        if diet:
            # 推荐食谱行
            recipe_section = ''
            rs_match = re.search(r'推荐食谱[：:]\s*\n(.+?)(?=\n\*\*|\n\n\n|$)', diet, re.DOTALL)
            if rs_match:
                recipe_section = rs_match.group(1)
            else:
                recipe_section = diet
            
            # 提取：去掉"宜食/忌食/原则"行，提取具体食谱
            items = bullet_items(recipe_section)
            for item in items:
                item = item.strip()
                # 跳过通用建议
                if any(k in item for k in ['宜食', '忌食', '原则', '不宜', '避免']):
                    continue
                if '：' in item or ':' in item:
                    parts = re.split(r'[：:]', item, 1)
                    rname = parts[0].strip()
                    rdesc = parts[1].strip() if len(parts) > 1 else ''
                else:
                    rname = item.split('、')[0].strip()
                    rdesc = item
                if len(rname) < 2: continue
                count += safe_insert(conn,
                    f"kb_solar_{name}_food_{hash(rname) % 999}",
                    rname, rdesc, 'food_therapy', f'{sc}季节气',
                    json.dumps(["节气", name, f"{sc}季"], ensure_ascii=False),
                    season_tag=season_tag)
        
        # 茶饮推荐
        tea = sections.get('茶饮推荐', '')
        if tea:
            items = bullet_items(tea)
            for item in items:
                if '：' in item or ':' in item:
                    parts = re.split(r'[：:]', item, 1)
                    tname = parts[0].strip()
                    tdesc = parts[1].strip() if len(parts) > 1 else ''
                else:
                    tname = item.strip()
                    tdesc = ''
                if len(tname) < 2: continue
                count += safe_insert(conn,
                    f"kb_solar_{name}_tea_{hash(tname) % 999}",
                    tname, tdesc, 'tea', f'{sc}季茶饮',
                    json.dumps(["茶饮", name, f"{sc}季"], ensure_ascii=False),
                    season_tag=season_tag)
        
        # 穴位保健
        acu = sections.get('穴位保健', '')
        if acu:
            # 格式: - 穴名：功效，位于...
            items = bullet_items(acu)
            for item in items:
                if '：' not in item and ':' not in item: continue
                parts = re.split(r'[：:]', item, 1)
                pname = parts[0].strip()
                pdesc = parts[1].strip() if len(parts) > 1 else ''
                # 提取位置
                loc = ''
                loc_m = re.search(r'位于(.+?)(?:[。，,]|$)', pdesc)
                if loc_m:
                    loc = loc_m.group(1).strip()
                if len(pname) < 2: continue
                count += safe_insert(conn,
                    f"kb_solar_{name}_acu_{hash(pname) % 999}",
                    pname, pdesc, 'acupoint', '节气穴位',
                    json.dumps(["穴位", name], ensure_ascii=False),
                    season_tag=season_tag, location=loc, effect=pname)
        
        # 运动建议
        ex = sections.get('运动建议', '')
        if ex:
            items = bullet_items(ex)
            for item in items[:5]:
                item = item.strip()
                if len(item) < 3: continue
                count += safe_insert(conn,
                    f"kb_solar_{name}_ex_{hash(item) % 999}",
                    item.split('：')[0].strip(), f'{name}时节运动',
                    'exercise', '季节运动',
                    json.dumps(["运动", name, f"{sc}季"], ensure_ascii=False),
                    season_tag=season_tag)
        
        # 情绪调养
        emo = sections.get('情绪调养', '')
        if emo:
            items = bullet_items(emo)
            desc = ' '.join([x.strip() for x in items if len(x.strip()) > 3][:5])
            if len(desc) > 10:
                count += safe_insert(conn,
                    f"kb_solar_{name}_emotion",
                    f'{name}情绪调养', desc, 'emotion', '节气情志',
                    json.dumps(["情绪", name, f"{sc}季"], ensure_ascii=False),
                    season_tag=season_tag)
        
        # 起居建议
        liv = sections.get('起居建议', '')
        if liv:
            items = bullet_items(liv)
            desc = ' '.join([x.strip() for x in items if len(x.strip()) > 3][:5])
            if len(desc) > 10:
                count += safe_insert(conn,
                    f"kb_solar_{name}_lifestyle",
                    f'{name}起居建议', desc, 'sleep_tip', '节气起居',
                    json.dumps(["起居", name, f"{sc}季"], ensure_ascii=False),
                    season_tag=season_tag)
    
    conn.commit()
    return count


def import_constitutions(content):
    """导入九种体质"""
    conn = get_db()
    count = 0
    
    # 匹配 ### X. 体质名体质
    pattern = r'###\s*\d*\.*\s*(.+?)体质\s*\n'
    splits = list(re.finditer(pattern, content))
    
    for i, m in enumerate(splits):
        name = m.group(1).strip()
        start = m.end()
        end = splits[i+1].start() if i+1 < len(splits) else start + 3000
        block = content[start:end]
        sections = split_sections(block)
        
        # 饮食调理
        for sec_key, ctype, cat in [('饮食调理','food_therapy','体质调理'), ('饮食建议','food_therapy','体质调理')]:
            text = sections.get(sec_key, '')
            if not text: continue
            items = bullet_items(text)
            for item in items[:5]:
                item = item.strip()
                if len(item) < 3: continue
                count += safe_insert(conn,
                    f"kb_const_{name}_food_{hash(item) % 999}",
                    item.split('：')[0].strip(), item,
                    ctype, cat,
                    json.dumps(["体质", f"{name}体质"], ensure_ascii=False))
            break
        
        # 茶饮
        for sec_key in ['茶饮', '茶饮推荐']:
            text = sections.get(sec_key, '')
            if not text: continue
            items = bullet_items(text)
            for item in items[:3]:
                item = item.strip()
                if len(item) < 3: continue
                count += safe_insert(conn,
                    f"kb_const_{name}_tea_{hash(item) % 999}",
                    item.split('：')[0].strip(), item,
                    'tea', '体质调理',
                    json.dumps(["茶饮", f"{name}体质"], ensure_ascii=False))
            break
        
        # 运动
        for sec_key in ['运动', '运动建议']:
            text = sections.get(sec_key, '')
            if not text: continue
            items = bullet_items(text)
            for item in items[:3]:
                item = item.strip()
                if len(item) < 3: continue
                count += safe_insert(conn,
                    f"kb_const_{name}_ex_{hash(item) % 999}",
                    item.split('：')[0].strip(), item,
                    'exercise', '体质调理',
                    json.dumps(["运动", f"{name}体质"], ensure_ascii=False))
            break
        
        # 穴位
        for sec_key in ['穴位保健', '穴位']:
            text = sections.get(sec_key, '')
            if not text: continue
            items = bullet_items(text)
            for item in items[:3]:
                if '：' not in item: continue
                parts = re.split(r'[：:]', item, 1)
                pname = parts[0].strip()
                if len(pname) < 2: continue
                count += safe_insert(conn,
                    f"kb_const_{name}_acu_{hash(pname) % 999}",
                    pname, parts[1].strip() if len(parts) > 1 else '',
                    'acupoint', '体质调理',
                    json.dumps(["穴位", f"{name}体质"], ensure_ascii=False))
            break
    
    conn.commit()
    return count


def import_chapters(content, prefix='kb_main'):
    """通用章节导入 — 食疗/茶饮/功法/睡眠/情绪/运动"""
    conn = get_db()
    count = 0
    
    # 按 ### 标题分割
    pattern = r'###\s*(.+?)\s*\n'
    splits = list(re.finditer(pattern, content))
    
    type_map = {
        '食疗': 'food_therapy', '茶饮': 'tea', '运动': 'exercise',
        '穴位': 'acupoint', '睡眠': 'sleep_tip', '情绪': 'emotion',
        '功法': 'exercise', '八段锦': 'exercise', '太极': 'exercise',
        '饮水': 'food_therapy', '家庭': 'food_therapy',
    }
    
    for i, m in enumerate(splits):
        title = m.group(1).strip()
        start = m.end()
        end = splits[i+1].start() if i+1 < len(splits) else len(content)
        block = content[start:end]
        
        # 判断类型
        ctype = 'food_therapy'
        for key, t in type_map.items():
            if key in title:
                ctype = t
                break
        
        items = bullet_items(block)
        for item in items[:8]:
            item = item.strip()
            if len(item) < 3: continue
            count += safe_insert(conn,
                f"{prefix}_{hash(title) % 10000}_{hash(item) % 999}",
                item.split('：')[0].strip(), item,
                ctype, '知识库',
                json.dumps(["知识库", title], ensure_ascii=False))
    
    conn.commit()
    return count


def import_supplement(content):
    """导入补充篇 — 按 #### 子板块深入导入"""
    conn = get_db()
    count = 0

    all_blocks = list(re.finditer(r'####\s*(.+?)\s*\n', content))

    age_labels = {
        '儿童': '儿童', '青少年': '青少年', '大学生': '年轻人',
        '职场': '白领', '备孕': '孕期', '中年': '中年',
        '退休': '退休', '高龄': '高龄老人', '特殊场景': '特殊',
        '生活方式': '生活方式', '体质复合': '复合体质',
    }

    for i, sm in enumerate(all_blocks):
        sec_title = sm.group(1).strip()
        sec_start = sm.end()
        sec_end = all_blocks[i+1].start() if i+1 < len(all_blocks) else len(content)
        sec_block = content[sec_start:sec_end]

        preceding = content[max(0, sec_start-500):sec_start]
        label = '其他'
        for key, lb in age_labels.items():
            if key in preceding:
                label = lb
                break

        # 判断类型
        ctype = 'food_therapy'
        ctag = '饮食'
        if any(k in sec_title for k in ['睡眠','入睡','助眠']):
            ctype = 'sleep_tip'; ctag = '睡眠'
        elif any(k in sec_title for k in ['运动','锻炼','推拿','拉伸','保健操']):
            ctype = 'exercise'; ctag = '运动'
        elif any(k in sec_title for k in ['情绪','心理','焦虑','压力','冥想','正念','倦怠','Burnout','抑郁']):
            ctype = 'emotion'; ctag = '情绪'
        elif any(k in sec_title for k in ['茶饮','茶']):
            ctype = 'tea'; ctag = '茶饮'
        elif any(k in sec_title for k in ['穴位','经络']):
            ctype = 'acupoint'; ctag = '穴位'
        elif any(k in sec_title for k in ['视力','眼']):
            ctype = 'exercise'; ctag = '视力保护'

        items = bullet_items(sec_block)

        if not items:
            bt_pattern = r'\*\*(.+?)[：:]\*\*\s*\n(.+?)(?=\n\*\*|\n\n\n|\n####|\Z)'
            for bt in re.finditer(bt_pattern, sec_block, re.DOTALL):
                bt_title = bt.group(1).strip()
                bt_content = bt.group(2).strip()
                sub_items = bullet_items(bt_content)
                for si in sub_items:
                    si = si.strip()
                    if len(si) < 3: continue
                    sub_ctype = ctype
                    if any(k in bt_title for k in ['食谱','营养','饮食','食物','奶']):
                        sub_ctype = 'food_therapy'
                    elif any(k in bt_title for k in ['推拿','手法','按摩']):
                        sub_ctype = 'exercise'
                    elif any(k in bt_title for k in ['助眠','睡眠']):
                        sub_ctype = 'sleep_tip'
                    count += safe_insert(conn,
                        f"kb_crowd_{label}_{hash(bt_title) % 999}_{hash(si) % 999}",
                        si.split('：')[0].strip()[:30], si,
                        sub_ctype, label,
                        json.dumps([label, bt_title[:10], ctag], ensure_ascii=False))
        else:
            for item in items[:8]:
                item = item.strip()
                if len(item) < 3: continue
                if '：' in item or ':' in item:
                    parts = re.split(r'[：:]', item, 1)
                    iname = parts[0].strip()
                    idesc = parts[1].strip() if len(parts) > 1 else item
                else:
                    iname = item[:25]
                    idesc = item
                count += safe_insert(conn,
                    f"kb_crowd_{label}_{hash(sec_title) % 999}_{hash(iname) % 999}",
                    iname, idesc, ctype, label,
                    json.dumps([label, sec_title[:10], ctag], ensure_ascii=False))

    conn.commit()
    return count

    conn.commit()
    return count


def import_wisdom_quotes(content):
    """导入养生名言到 wisdom 系统"""
    # 这个已经在 wisdom.py 中了，不需要重复导入
    return 0


def main():
    # 1. 主知识库
    main_path = os.path.join(BASE, '顺时知识库_中文版.md')
    with open(main_path, 'r', encoding='utf-8') as f:
        main_content = f.read()
    
    print(f"主知识库: {len(main_content)} 字符")
    
    c1 = import_solar_terms(main_content)
    print(f"  24节气: +{c1}")
    
    c2 = import_constitutions(main_content)
    print(f"  体质调理: +{c2}")
    
    # 食疗、茶饮、功法、睡眠、情绪等章节
    chapters_text = main_content
    c3 = import_chapters(chapters_text, 'kb_ch3')
    print(f"  各章节内容: +{c3}")
    
    # 2. 补充篇
    supp_path = os.path.join(BASE, '顺时知识库_补充篇_中文版.md')
    with open(supp_path, 'r', encoding='utf-8') as f:
        supp_content = f.read()
    
    print(f"\n补充篇: {len(supp_content)} 字符")
    
    c5 = import_supplement(supp_content)
    print(f"  人群方案: +{c5}")
    
    # 统计
    conn = get_db()
    total = conn.execute('SELECT COUNT(*) FROM contents').fetchone()[0]
    types = conn.execute('SELECT type, COUNT(*) as c FROM contents GROUP BY type ORDER BY c DESC').fetchall()
    
    print(f"\n=== 数据库总计: {total} 条 ===")
    for r in types:
        print(f"  {r[0]:20s} {r[1]:>4d}")
    
    # knowledge_base 前缀的统计
    kb = conn.execute("SELECT COUNT(*) FROM contents WHERE id LIKE 'kb_%'").fetchone()[0]
    print(f"\n知识库导入: {kb} 条 (kb_ 前缀)")


if __name__ == '__main__':
    main()
