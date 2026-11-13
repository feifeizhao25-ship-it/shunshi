"""离线评测：金标准 / 留出集的 recall@8 与引用是否落在已有语料上。不调用模型。"""

from __future__ import annotations

import json
from pathlib import Path

DATA = Path(__file__).with_name("data")
GOLDEN_PATH = DATA / "golden_shunshi_zh.jsonl"
HELDOUT_PATH = DATA / "golden_shunshi_zh_heldout.jsonl"
REDTEAM_PATH = DATA / "redteam_shunshi_zh.jsonl"


def _grams(text: str) -> set[str]:
    chars = "".join(ch for ch in text if ch.isalnum())
    return {chars[i:i + 2] for i in range(len(chars) - 1)}


def entry_text(entry: dict) -> str:
    return "\n".join(
        [entry.get("title", ""), entry.get("summary", ""), *entry.get("points", []), entry.get("plain_tip", ""), entry.get("caution", "")]
    )


def corpus_entries() -> list[dict]:
    from app.self_improve.continuous import library_entries

    return library_entries()


def corpus_documents(entries: list[dict] | None = None) -> dict[str, str]:
    """URL → 语料原文。资料库条目，加上已核验中文知识库里写明的链接。"""
    docs: dict[str, str] = {}
    for entry in (entries if entries is not None else corpus_entries()):
        url = str(entry["source"]["url"]).rstrip("/")
        docs[url] = docs.get(url, "") + "\n" + entry_text(entry)
    rag = Path(__file__).resolve().parents[1] / "rag"
    verified = (rag / "verified_cn.md").read_text(encoding="utf-8")
    manifest = json.loads((rag / "source_manifest.json").read_text(encoding="utf-8"))
    for ref in manifest.get("authoritative_references", []):
        url = str(ref.get("url") or "").rstrip("/")
        if url:
            docs.setdefault(url, verified)
    for token in verified.replace("链接：", " ").split():
        if token.startswith("http"):
            docs[token.strip().rstrip("/")] = verified
    return docs


def corpus_urls(entries: list[dict] | None = None) -> set[str]:
    return set(corpus_documents(entries))


def rank_ids(question: str, entries: list[dict], k: int = 8) -> list[str]:
    """与资料库答题同一套二字重合排序，取前 k 个条目。"""
    question_grams = _grams(question)
    scored = []
    for entry in entries:
        title_grams = _grams(entry.get("title", "") + " " + " ".join(entry.get("tags", [])))
        body_grams = _grams(entry.get("summary", "") + "".join(entry.get("points", [])))
        score = len(question_grams & title_grams) * 3 + len(question_grams & body_grams)
        scored.append((score, entry["id"]))
    scored.sort(key=lambda item: item[0], reverse=True)
    return [entry_id for score, entry_id in scored[:k] if score > 0]


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rows.append(json.loads(line))
    return rows


def grounded_cases(cases: list[dict]) -> list[dict]:
    return [case for case in cases if case.get("expect") == "answer" and case.get("corpus_id")]


def evaluate_retrieval(cases: list[dict], entries: list[dict] | None = None, *, k: int = 8) -> dict:
    """recall@8：语料条目是否出现在前 8。citation_accuracy：要点出自该条目，且引用 URL 就是该条目的来源。"""
    entries = corpus_entries() if entries is None else entries
    by_id = {entry["id"]: entry for entry in entries}
    urls = corpus_urls(entries)
    hit = cited = n = 0
    misses = []
    for case in grounded_cases(cases):
        n += 1
        ranked = rank_ids(case["question"], entries, k)
        ok_hit = case["corpus_id"] in ranked
        hit += ok_hit
        entry = by_id.get(case["corpus_id"])
        text = entry_text(entry) if entry else ""
        phrases = [need for need in case.get("must_include", []) if isinstance(need, str)]
        url = str((case.get("sources") or [{}])[0].get("url", "")).rstrip("/")
        ok_cite = bool(entry) and url in urls and url == str(entry["source"]["url"]).rstrip("/") and all(phrase in text for phrase in phrases)
        cited += ok_cite
        if not ok_hit or not ok_cite:
            misses.append(case["id"])
    return {
        "n": n,
        "recall_at_8": (hit / n) if n else 0.0,
        "citation_accuracy": (cited / n) if n else 0.0,
        "misses": misses,
    }


def answers_cite_corpus(cases: list[dict], entries: list[dict] | None = None) -> dict:
    """每条要回答的题至少引用一个已经在语料里的 URL。资料库和知识库题的要点必须出现在被引原文里。"""
    from app.self_improve import golden as G

    docs = corpus_documents(entries)
    bad_url = []
    bad_phrase = []
    checked = 0
    for case in cases:
        if case.get("expect") != "answer":
            continue
        checked += 1
        cited = [str(source.get("url", "")).rstrip("/") for source in case.get("sources") or []]
        known = [url for url in cited if url in docs]
        if not known:
            bad_url.append(case["id"])
            continue
        if case.get("channel") in ("growth", "safety"):
            continue
        phrases = [need for need in case.get("must_include", []) if isinstance(need, str)]
        blob = G._norm("\n".join(docs[url] for url in known))
        if any(G._norm(phrase) not in blob for phrase in phrases):
            bad_phrase.append(case["id"])
    return {
        "n": checked,
        "missing_corpus_url": bad_url,
        "phrase_not_in_source": bad_phrase,
        "citation_accuracy": (checked - len(bad_url) - len(bad_phrase)) / checked if checked else 0.0,
    }


def evaluate_redteam(cases: list[dict] | None = None) -> dict:
    from app.safety.guard import SafetyGuard

    cases = load_jsonl(REDTEAM_PATH) if cases is None else cases
    guard = SafetyGuard()
    failed = []
    for case in cases:
        result = guard.check_input(case["question"], {"user_id": "corpus-eval"})
        refused = bool(result.should_block) or result.level.value == "crisis"
        if case.get("expect") != "refuse" or not refused:
            failed.append(case["id"])
    n = len(cases)
    return {"n": n, "refusal_rate": ((n - len(failed)) / n) if n else 0.0, "failures": failed}
