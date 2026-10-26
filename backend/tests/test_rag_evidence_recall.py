from datetime import date, timedelta
from types import SimpleNamespace
from app.rag import retriever


def test_verified_passage_is_not_crowded_out_by_legacy(monkeypatch):
    chunks=[SimpleNamespace(chunk_id=str(i),content='睡眠',heading_path=['睡眠'],metadata={'evidence_status':'legacy_unverified'}) for i in range(45)]
    chunks.append(SimpleNamespace(chunk_id='official',content='睡眠科普',heading_path=['官方'],metadata={'evidence_status':'verified_official','valid_until':(date.today()+timedelta(days=1)).isoformat()}))
    chunks.append(SimpleNamespace(chunk_id='invalid',content='睡眠',heading_path=[],metadata={'evidence_status':'verified_official','valid_until':'bad'}))
    monkeypatch.setattr(retriever,'cn_kb',SimpleNamespace(loaded=True,chunks=chunks))
    monkeypatch.setattr(retriever,'get_embedder',lambda _:SimpleNamespace(query=lambda q,top_k:[(i,1-i*.01) for i in range(len(chunks))][:top_k]))
    hits=retriever.retrieve('睡眠',top_k=3,verified_only=True)
    assert [h['chunk_id'] for h in hits]==['official']
    assert retriever.retrieve('睡眠',top_k=0,verified_only=True)==[]
