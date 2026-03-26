"""
知识库加载与分块模块
按 Markdown 标题层级自动分块，保留元数据
支持主库 + 补充篇
"""
import re
import os
import logging
from typing import Optional
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)

# 默认知识库路径
_DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "data")
_CN_PATH = os.path.join(_DATA_DIR, "knowledge_base_cn.md")
_GL_PATH = os.path.join(_DATA_DIR, "knowledge_base_gl.md")
_CN_SUPP_PATH = os.path.join(_DATA_DIR, "knowledge_base_cn_supplement.md")
_GL_SUPP_PATH = os.path.join(_DATA_DIR, "knowledge_base_gl_supplement.md")

# 中文知识库标题 → 分类/季节/节气的映射
_CN_SEASON_MAP = {
    "第一章": "节气", "春季节气": "春", "夏季节气": "夏",
    "秋季节气": "秋", "冬季节气": "冬",
}
_CN_CATEGORY_MAP = {
    "第一章": "节气", "第二章": "体质", "第三章": "食疗",
    "第四章": "茶饮", "第五章": "运动", "第六章": "穴位",
    "第七章": "情绪", "第八章": "女性", "第九章": "男性",
    "第十章": "老年", "第十一章": "饮水", "第十二章": "日记",
    "第十三章": "误区", "第十四章": "对话", "第十五章": "文化",
}

# 补充篇标题 → 年龄段映射
_SUPP_AGE_GROUP_MAP = {
    "儿童养生": "children",
    "学龄前": "children",
    "学龄儿童": "children",
    "青少年": "teenager",
    "大学生": "young_adult",
    "年轻人": "young_adult",
    "职场": "professional",
    "白领": "professional",
    "备孕": "professional",
    "孕期": "professional",
    "产后": "professional",
    "中年人": "middle_age",
    "更年期": "middle_age",
    "围绝经期": "middle_age",
    "退休": "senior",
    "活力老人": "senior",
    "高龄老人": "elderly",
}

# 补充篇标题 → 场景映射
_SUPP_SCENARIO_MAP = {
    "出差": "business_trip",
    "商旅": "business_trip",
    "夜班": "night_shift",
    "倒班": "night_shift",
    "健身": "fitness",
    "运动达人": "fitness",
    "电子设备": "desk_work",
    "久坐": "desk_work",
    "情绪困扰": "stress",
    "焦虑": "stress",
    "抑郁": "stress",
    "素食": "vegetarian",
    "减重": "weight_loss",
    "控重": "weight_loss",
    "备考": "exam_prep",
    "考试": "exam_prep",
    "新手父母": "parent",
    "育儿": "parent",
}

# 英文知识库标题 → 分类映射
_GL_CATEGORY_MAP = {
    "Chapter 1": "Seasonal Living", "Chapter 2": "Sleep",
    "Chapter 3": "Emotional Wellness", "Chapter 4": "Breathing & Meditation",
    "Chapter 5": "Movement", "Chapter 6": "Tea",
    "Chapter 7": "Nutrition", "Chapter 8": "Journaling",
    "Chapter 9": "AI Companion", "Chapter 10": "Wellness Rituals",
    "Chapter 11": "Family Wellness",
}

# 英文补充篇 → 年龄段映射
_GL_SUPP_AGE_GROUP_MAP = {
    "Children": "children",
    "Teenagers": "teenager",
    "Young Adults": "young_adult",
    "Professionals": "professional",
    "Middle-Aged": "middle_age",
    "Seniors": "senior",
    "Elderly": "elderly",
}


@dataclass
class KnowledgeChunk:
    """知识库分块"""
    chunk_id: str
    content: str
    heading_path: list  # e.g. ["第一章：二十四节气养生", "一、春季节气", "1. 立春"]
    metadata: dict = field(default_factory=dict)

    @property
    def path_str(self) -> str:
        return " / ".join(self.heading_path)


def _parse_markdown_into_chunks(
    text: str,
    lang: str,
    target_chunk_size: int = 600,
    overlap_ratio: float = 0.3,
    source: str = "main",
) -> list[KnowledgeChunk]:
    """
    将 Markdown 文本按标题层级切分成 chunks。

    策略:
    1. 先按 #### (level 4) 切分，每个 section 作为一个候选块
    2. 如果某 section 太长，按段落再切分并保留重叠
    3. 每个 chunk 保留完整的标题路径和 metadata
    """
    lines = text.split("\n")
    chunks: list[KnowledgeChunk] = []
    chunk_counter = 0

    # 用正则识别标题行及其层级
    heading_re = re.compile(r"^(#{2,4})\s+(.+)$")

    current_h2 = ""
    current_h3 = ""
    current_h4 = ""
    current_section_lines: list[str] = []
    current_metadata: dict = {"source": source}

    def _flush_section():
        nonlocal chunk_counter
        content = "\n".join(current_section_lines).strip()
        if not content or len(content) < 30:
            return

        heading_path = []
        if current_h2:
            heading_path.append(current_h2)
        if current_h3:
            heading_path.append(current_h3)
        if current_h4:
            heading_path.append(current_h4)

        # 如果块太长，按段落二次切分
        if len(content) > target_chunk_size * 1.8:
            _split_long_content(
                content, heading_path, current_metadata, lang,
                target_chunk_size, overlap_ratio, chunks
            )
        else:
            chunk_counter += 1
            chunks.append(KnowledgeChunk(
                chunk_id=f"{lang}_{chunk_counter:04d}",
                content=content,
                heading_path=heading_path,
                metadata=dict(current_metadata),
            ))

    for line in lines:
        m = heading_re.match(line)
        if m:
            # 遇到新标题 → flush 当前 section
            _flush_section()
            current_section_lines = [line]
            level = len(m.group(1))
            title = m.group(2).strip()

            if level == 2:
                current_h2 = title
                current_h3 = ""
                current_h4 = ""
                current_metadata = _extract_metadata(title, lang, source=source)
            elif level == 3:
                current_h3 = title
                current_h4 = ""
                # 补充 metadata
                extra = _extract_metadata(title, lang, parent=current_h2, source=source)
                current_metadata.update(extra)
            elif level == 4:
                current_h4 = title
                extra = _extract_metadata(title, lang, parent_h3=current_h3, source=source)
                current_metadata.update(extra)
        else:
            current_section_lines.append(line)

    # flush 最后一个 section
    _flush_section()

    logger.info(f"[KB] 解析完成: lang={lang}, source={source}, chunks={len(chunks)}")
    return chunks


def _split_long_content(
    content: str,
    heading_path: list,
    metadata: dict,
    lang: str,
    target_size: int,
    overlap_ratio: float,
    chunks: list,
):
    """将过长的内容按段落切分，保留重叠"""
    paragraphs = re.split(r"\n{2,}", content)
    buffer_lines: list[str] = []
    buffer_len = 0
    overlap_size = int(target_size * overlap_ratio)
    chunk_counter = sum(1 for c in chunks if c.chunk_id.startswith(f"{lang}_"))
    sub_counter = 0

    def _flush_buffer():
        nonlocal chunk_counter, sub_counter
        text = "\n\n".join(buffer_lines).strip()
        if not text or len(text) < 30:
            return
        sub_counter += 1
        chunk_counter += 1
        chunks.append(KnowledgeChunk(
            chunk_id=f"{lang}_{chunk_counter:04d}_{sub_counter}",
            content=text,
            heading_path=list(heading_path),
            metadata=dict(metadata),
        ))

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue

        buffer_lines.append(para)
        buffer_len += len(para)

        if buffer_len >= target_size:
            _flush_buffer()
            # 保留重叠：保留末尾几段
            overlap_lines: list[str] = []
            overlap_len = 0
            for bl in reversed(buffer_lines):
                if overlap_len + len(bl) > overlap_size:
                    break
                overlap_lines.insert(0, bl)
                overlap_len += len(bl)
            buffer_lines = overlap_lines
            buffer_len = overlap_len

    # flush 剩余
    if buffer_lines:
        _flush_buffer()


def _extract_metadata(title: str, lang: str, parent: str = "", parent_h3: str = "", source: str = "main") -> dict:
    """从标题提取 metadata"""
    meta: dict = {"source": source}

    if lang == "cn":
        # 提取分类
        for key, cat in _CN_CATEGORY_MAP.items():
            if key in title:
                meta["category"] = cat
                break
        # 提取季节
        for key, season in _CN_SEASON_MAP.items():
            if key in title:
                meta["season"] = season
                break
        if "春" in title and "季节" in title:
            meta["season"] = "春"
        elif "夏" in title and "季节" in title:
            meta["season"] = "夏"
        elif "秋" in title and "季节" in title:
            meta["season"] = "秋"
        elif "冬" in title and "季节" in title:
            meta["season"] = "冬"

        # 从 #### 标题提取节气
        if parent_h3 and "节气" in parent_h3:
            solar_terms = [
                "立春", "雨水", "惊蛰", "清明", "谷雨",
                "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
                "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
                "立冬", "小雪", "大雪", "冬至", "小寒", "大寒",
            ]
            for st in solar_terms:
                if st in title:
                    meta["solar_term"] = st
                    break

        # 从 #### 标题提取体质
        constitutions = ["平和", "气虚", "阳虚", "阴虚", "痰湿", "湿热", "血瘀", "气郁", "特禀"]
        for c in constitutions:
            if c in title:
                meta["constitution"] = c
                break

        # 提取子类别
        sub_categories = ["饮食", "运动", "茶饮", "穴位", "情绪", "食疗", "运动操", "误区", "名言"]
        for sc in sub_categories:
            if sc in title:
                meta["sub_category"] = sc
                break

        # 补充篇额外 metadata: age_group, scenario
        if source == "supplement":
            # 合并 parent + title + parent_h3 进行匹配
            combined = f"{parent} {title} {parent_h3}"
            for key, age_group in _SUPP_AGE_GROUP_MAP.items():
                if key in combined:
                    meta["age_group"] = age_group
                    break
            for key, scenario in _SUPP_SCENARIO_MAP.items():
                if key in combined:
                    meta["scenario"] = scenario
                    break

    else:
        # 英文
        for key, cat in _GL_CATEGORY_MAP.items():
            if key in title:
                meta["category"] = cat
                break
        # 提取季节
        seasons_map = {
            "Spring": "spring", "Summer": "summer",
            "Autumn": "autumn", "Winter": "winter",
        }
        for key, val in seasons_map.items():
            if key in title:
                meta["season"] = val
                break

        # 补充篇额外 metadata: age_group
        if source == "supplement":
            combined = f"{parent} {title} {parent_h3}"
            for key, age_group in _GL_SUPP_AGE_GROUP_MAP.items():
                if key in combined:
                    meta["age_group"] = age_group
                    break

    return meta


class KnowledgeBase:
    """内存中的知识库"""

    def __init__(self, lang: str):
        self.lang = lang
        self.chunks: list[KnowledgeChunk] = []
        self.loaded = False

    def load(self, path: Optional[str] = None):
        """从 markdown 文件加载"""
        if path is None:
            path = _CN_PATH if self.lang == "cn" else _GL_PATH

        if not os.path.exists(path):
            logger.warning(f"[KB] 知识库文件不存在: {path}")
            return

        with open(path, "r", encoding="utf-8") as f:
            text = f.read()

        new_chunks = _parse_markdown_into_chunks(text, self.lang, source="main")
        self.chunks.extend(new_chunks)
        self.loaded = True
        logger.info(f"[KB] {self.lang} 主知识库加载完成: {len(new_chunks)} chunks")

    def load_supplement(self, path: Optional[str] = None):
        """加载补充篇知识库"""
        if path is None:
            path = _CN_SUPP_PATH if self.lang == "cn" else _GL_SUPP_PATH

        if not os.path.exists(path):
            logger.warning(f"[KB] 补充篇不存在: {path}")
            return

        with open(path, "r", encoding="utf-8") as f:
            text = f.read()

        new_chunks = _parse_markdown_into_chunks(text, self.lang, source="supplement")
        self.chunks.extend(new_chunks)
        logger.info(f"[KB] {self.lang} 补充篇加载完成: {len(new_chunks)} chunks, 总计: {len(self.chunks)}")

    def get_all_content(self) -> str:
        """获取所有内容（用于 TF-IDF 训练）"""
        return "\n\n".join([c.content for c in self.chunks])

    def get_stats(self) -> dict:
        """获取统计信息"""
        categories = set()
        seasons = set()
        age_groups = set()
        total_chars = 0
        main_count = 0
        supp_count = 0

        for chunk in self.chunks:
            if chunk.metadata.get("category"):
                categories.add(chunk.metadata["category"])
            if chunk.metadata.get("season"):
                seasons.add(chunk.metadata["season"])
            if chunk.metadata.get("age_group"):
                age_groups.add(chunk.metadata["age_group"])
            total_chars += len(chunk.content)
            if chunk.metadata.get("source") == "supplement":
                supp_count += 1
            else:
                main_count += 1

        return {
            "lang": self.lang,
            "total_chunks": len(self.chunks),
            "main_chunks": main_count,
            "supplement_chunks": supp_count,
            "total_chars": total_chars,
            "categories": sorted(categories),
            "seasons": sorted(seasons),
            "age_groups": sorted(age_groups),
            "loaded": self.loaded,
        }

    def get_categories(self) -> list[str]:
        """获取所有分类"""
        cats = set()
        for chunk in self.chunks:
            if chunk.metadata.get("category"):
                cats.add(chunk.metadata["category"])
        return sorted(cats)


# 全局知识库实例
cn_kb = KnowledgeBase("cn")
gl_kb = KnowledgeBase("gl")


def load_knowledge_bases():
    """启动时加载所有知识库（主库 + 补充篇）"""
    logger.info("[KB] 开始加载知识库...")
    cn_kb.load()
    cn_kb.load_supplement()
    gl_kb.load()
    gl_kb.load_supplement()
    logger.info(f"[KB] 加载完成: CN={len(cn_kb.chunks)} chunks, GL={len(gl_kb.chunks)} chunks")
