"""批3: 报告导出(PDF/Docx/Md) + 记忆更新/搜索/保留期 + 生命周期历史."""
from app.services.report_export import build_docx, build_markdown, build_pdf
from app.services.memory_system import memory_system

MEMOS=[{"type":"preference","content":"喜欢清淡饮食","created_at":"2026-10-01"}]

def test_report_formats():
    assert build_markdown("u1", MEMOS).decode().startswith("# 顺时")
    docx=build_docx("u1", MEMOS)
    assert docx[:2]==b"PK" and len(docx)>500
    pdf=build_pdf("u1", MEMOS)
    assert pdf[:4]==b"%PDF" and len(pdf)>1000

def test_memory_update_search_retention(tmp_path, monkeypatch):
    # memory_system uses app db; use its public API with a unique user
    uid="batch3-test-user"
    item=memory_system.update_user_memory(user_id=uid, memory_type="preference", content="爱喝菊花茶", confidence=1.0, source="manual")
    found=memory_system.search_memories(uid, "菊花")
    assert any("菊花" in (m.get("content") or "") for m in found)
    assert memory_system.update_memory_content(item.id, uid, "爱喝枸杞茶")
    assert any("枸杞" in (m.get("content") or "") for m in memory_system.search_memories(uid, "枸杞"))
    assert memory_system.update_memory_content(item.id, "someone-else", "x") is False
    memory_system.set_retention_days(uid, 3650)
    assert memory_system.get_retention_days(uid)==3650
    memory_system.delete_all_memories(uid)

def test_lifecycle_history_records_and_lists():
    # 直接测路由函数 (HTTP 层另有 product_access_guard 本人校验, 见 test_memory 的 403 契约)
    import asyncio
    from app.router.lifecycle import _record_history, get_lifecycle_history
    _record_history("batch3-life-user", 1990, "stable", 36)
    data = asyncio.run(get_lifecycle_history(user_id="batch3-life-user", limit=50))
    assert data["count"] >= 1 and data["history"][0]["birth_year"] == 1990

def test_memory_report_endpoint_requires_auth(client):
    assert client.get("/api/v1/memory/report").status_code in (401, 403)
    assert client.get("/api/v1/memory/search", params={"q": "茶"}).status_code in (401, 403)
