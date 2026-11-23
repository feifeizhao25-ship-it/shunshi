"""来源卡「复核日期」取每一节正文里的「顺时复核日期」，不取整份文件的日期（问题 5）。"""
from app.rag.knowledge_base import cn_kb, load_knowledge_bases


def _by_id():
    load_knowledge_bases(include_legacy=False, force=True)
    return {c.chunk_id: c for c in cn_kb.chunks if c.metadata.get("source_file") == "verified_cn.md"}


def test_each_section_uses_its_own_review_date():
    chunks = _by_id()
    assert chunks["cn_0004"].metadata["reviewed_at"] == "2026-11-01"   # 饮水：正文 2026-11-01
    assert chunks["cn_0005"].metadata["reviewed_at"] == "2026-11-01"   # 身体活动
    assert chunks["cn_0001"].metadata["reviewed_at"] == "2026-08-30"   # 八项原则：正文 2026-08-30


def test_card_date_matches_the_text_for_every_section():
    import re
    for chunk in _by_id().values():
        m = re.search(r"顺时复核日期：(\d{4}-\d{2}-\d{2})", chunk.content)
        if m:
            assert chunk.metadata["reviewed_at"] == m.group(1), chunk.chunk_id
