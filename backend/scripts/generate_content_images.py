"""
AI 图片生成脚本
为知识库中的所有内容生成配图
使用 SiliconFlow API (FLUX 模型)
"""

import os
import sys
import json
import time
import hashlib
import requests
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database.db import get_db, row_to_dict

# SiliconFlow API 配置
API_KEY = os.getenv("SILICONFLOW_API_KEY", "")
BASE_URL = "https://api.siliconflow.cn/v1"

# 图片保存目录
IMAGE_DIR = Path(__file__).parent.parent / "static" / "images" / "contents"
IMAGE_DIR.mkdir(parents=True, exist_ok=True)


def _parse_json(val):
    if not val or val in ("[]", "null"):
        return []
    try:
        return json.loads(val) if isinstance(val, str) else val
    except:
        return []


def generate_image_prompt(item: dict) -> str:
    """根据内容类型和标签生成图片 Prompt"""
    content_type = item.get("type", "")
    title = item.get("title", "")
    tags = _parse_json(item.get("tags", []))
    description = (item.get("description") or "")[:200]
    season = item.get("season_tag", "")
    ingredients = _parse_json(item.get("ingredients", []))

    season_cn = {"spring": "春季", "summer": "夏季", "autumn": "秋季", "winter": "冬季"}.get(season, "")
    tag_str = "、".join(tags[:5]) if tags else ""

    if content_type == "food_therapy":
        ing_str = "、".join(ingredients[:4]) if ingredients else ""
        return f"Chinese traditional wellness food photography, {title}, top-down view, warm lighting, ceramic bowls, wooden table, {ing_str}, traditional Chinese medicine food therapy aesthetic, high quality food photography, 4k"
    elif content_type == "tea":
        ing_str = "、".join(ingredients[:3]) if ingredients else ""
        return f"Chinese tea ceremony photography, {title}, {ing_str}, tea set, soft natural light, steam rising, minimalist zen style, traditional Chinese aesthetic, warm tones, 4k"
    elif content_type == "tea":
        return f"Chinese tea close-up, {title}, teapot, porcelain cup, steam, soft light, zen atmosphere, warm tones, 4k"
    elif content_type == "exercise":
        return f"Wellness exercise silhouette, {title}, outdoor natural setting, {season_cn} scenery, soft morning light, peaceful atmosphere, minimalist style, 4k"
    elif content_type == "acupressure":
        return f"Traditional Chinese medicine acupoint illustration, {title}, clean minimalist style, anatomical diagram, soft colors, professional medical illustration, 4k"
    elif content_type == "sleep_tip":
        return f"Peaceful bedroom scene, {title}, warm ambient light, cozy bedding, minimalist interior, calm atmosphere, night time, 4k"
    elif content_type == "emotion":
        return f"Healing nature landscape, {title}, {season_cn} scenery, soft light, peaceful atmosphere, traditional Chinese aesthetic, serene mood, 4k"
    elif content_type == "acupoint":
        return f"Acupuncture point diagram, {title}, human body illustration, clean lines, minimalist medical style, soft blue tones, 4k"
    elif content_type == "recipe":
        ing_str = "、".join(ingredients[:3]) if ingredients else ""
        return f"Traditional Chinese recipe, {title}, {ing_str}, cooking scene, warm kitchen, ceramic dish, food photography, 4k"
    else:
        return f"Traditional Chinese wellness lifestyle, {title}, {tag_str}, warm aesthetic, natural lighting, 4k"


def generate_image(prompt: str, output_path: Path, max_retries: 2) -> bool:
    """调用 SiliconFlow API 生成图片"""
    if not API_KEY:
        print("  ⚠️  No SILICONFLOW_API_KEY, skipping image generation")
        return False

    for attempt in range(max_retries + 1):
        try:
            resp = requests.post(
                f"{BASE_URL}/images/generations",
                headers={"Authorization": f"Bearer {API_KEY}"},
                json={
                    "model": "black-forest-labs/FLUX.1-schnell",
                    "prompt": prompt,
                    "image_size": "1024x1024",
                    "num_inference_steps": 20,
                    "batch_size": 1,
                },
                timeout=60,
            )
            if resp.status_code == 200:
                data = resp.json()
                images = data.get("images", data.get("results", []))
                if images:
                    url = images[0].get("url", "")
                    if url:
                        img_resp = requests.get(url, timeout=30)
                        if img_resp.status_code == 200:
                            output_path.write_bytes(img_resp.content)
                            return True
                        print(f"  ⚠️  Failed to download image: {img_resp.status_code}")
                # 可能是不同格式
                if "images" in data and isinstance(data["images"], list) and data["images"]:
                    img_data = data["images"][0]
                    if isinstance(img_data, str):
                        # base64
                        import base64
                        output_path.write_bytes(base64.b64decode(img_data))
                        return True
            elif resp.status_code == 429:
                print(f"  ⚠️  Rate limited, waiting 10s...")
                time.sleep(10)
                continue
            else:
                print(f"  ⚠️  API error: {resp.status_code} {resp.text[:100]}")
        except Exception as e:
            print(f"  ⚠️  Error (attempt {attempt+1}): {e}")
            if attempt < max_retries:
                time.sleep(5)
    return False


def generate_svg_placeholder(item: dict, output_path: Path):
    """生成一个美观的 SVG 占位图 (当 API 不可用时)"""
    content_type = item.get("type", "")
    title = item.get("title", "")[:6]
    season = item.get("season_tag", "")

    # 按内容类型选择颜色方案
    color_schemes = {
        "food_therapy": ("#D4A574", "#F5E6D3", "🍲"),  # 暖色 - 食疗
        "tea": ("#8B7355", "#F0E6D6", "🍵"),            # 茶色 - 茶饮
        "exercise": ("#7EB09B", "#E8F5E9", "🧘"),       # 绿色 - 运动
        "acupressure": ("#C19A6B", "#FFF3E0", "🫳"),    # 棕色 - 穴位
        "sleep_tip": ("#7B9EC7", "#E3F2FD", "🌙"),      # 蓝色 - 睡眠
        "emotion": ("#B39DDB", "#F3E5F5", "🌸"),        # 紫色 - 情绪
        "acupoint": ("#C19A6B", "#FFF3E0", "📍"),        # 棕色 - 穴位
        "recipe": ("#D4A574", "#F5E6D3", "📖"),          # 暖色 - 食谱
    }
    primary, bg, emoji = color_schemes.get(content_type, ("#888", "#F5F5F5", "🌿"))

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{bg};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{primary}22;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="800" height="600" fill="url(#bg)" rx="16"/>
  <circle cx="400" cy="240" r="80" fill="{primary}22"/>
  <text x="400" y="260" text-anchor="middle" font-size="72">{emoji}</text>
  <text x="400" y="360" text-anchor="middle" font-family="sans-serif" font-size="32" font-weight="bold" fill="{primary}">{title}</text>
  <text x="400" y="410" text-anchor="middle" font-family="sans-serif" font-size="18" fill="{primary}99">顺时养生</text>
</svg>"""
    output_path.write_text(svg, encoding="utf-8")


def main():
    print("🚀 开始为知识库内容生成配图...")

    db = get_db()
    conn = db.execute("SELECT * FROM contents WHERE locale = 'zh-CN' ORDER BY type, id")
    items = [row_to_dict(r) for r in conn.fetchall()]
    print(f"共 {len(items)} 条内容需要处理")

    # 按类型统计
    type_counts = {}
    for item in items:
        t = item["type"]
        type_counts[t] = type_counts.get(t, 0) + 1
    print(f"类型分布: {type_counts}")

    generated = 0
    skipped = 0

    for i, item in enumerate(items):
        content_id = item["id"]
        title = item["title"]
        content_type = item["type"]
        ext = ".svg"  # 默认 SVG 占位图

        # 检查是否已有图片
        existing_url = item.get("image_url", "")
        if existing_url:
            skipped += 1
            continue

        # 生成文件名
        filename = f"{content_id}{ext}"
        output_path = IMAGE_DIR / filename

        # 如果已生成，跳过
        if output_path.exists():
            # 更新数据库
            db.execute("UPDATE contents SET image_url = ? WHERE id = ?",
                       (f"/static/images/contents/{filename}", content_id))
            db.commit()
            generated += 1
            continue

        print(f"[{i+1}/{len(items)}] {content_type}: {title}")

        # 生成 SVG 占位图 (快速模式)
        generate_svg_placeholder(item, output_path)
        db.execute("UPDATE contents SET image_url = ? WHERE id = ?",
                   (f"/static/images/contents/{filename}", content_id))
        db.commit()
        generated += 1
        print(f"  📝 SVG: {output_path.name}")

    print(f"\n📊 完成! 生成:{generated} 跳过:{skipped}")
    print(f"图片目录: {IMAGE_DIR}")


if __name__ == "__main__":
    main()
