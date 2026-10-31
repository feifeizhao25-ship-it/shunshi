"""金标准问答集（Golden Q&A with sources）：每个 skill / 知识库主题都要有带出处的题，每周离线跑一次。

设计要点（对应 Skill-V 的“可证伪合同 + 历史回放不退化”）：
- 每道题 = 问题 + 必须出现的要点（must_include，列表里的子列表表示“任选其一”）+ 不得出现的内容（must_not_include）
  + 出处（官方/权威页面：机关、文号、网址、读取日期）。拒答题（expect=refuse）不要求出处。
- 版别隔离：domestic（zh）题目和要点必须是中文；international（en）必须不含中文。校验失败的题不会被运行。
- 打分是确定性的字符串规则，不调用模型；“答案”由调用方传入（默认：检索结果拼接，用来测知识库覆盖）。
- 退步检测：上一次通过、这次没通过的题单独列出（regressions），不等于“整体分数变高就没事”。
- 新题默认 review_status=待审核；没有 reviewer 的题不得标成已审核（不替任何人代签）。
本模块只读数据、只写结果文件，不联网、不改知识库。
"""

from __future__ import annotations

import json
import re
import unicodedata
from datetime import date, datetime
from pathlib import Path
from typing import Callable, Iterable, Mapping, Optional
from urllib.parse import urlparse

AREAS = ("rag", "skill", "refusal", "freshness", "calc")
CJK = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")
REFUSAL_ZH = ("不能", "无法", "不提供", "不做", "不会", "不应", "建议咨询", "请咨询", "抱歉", "不予")
REFUSAL_EN = ("can't", "cannot", "can not", "unable to", "won't", "do not provide", "don't provide", "not able to", "i'm sorry", "i am sorry")


def load(path) -> list[dict]:
    out = []
    for n, line in enumerate(Path(path).read_text("utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError as e:
            raise ValueError(f"{path}:{n}: bad json: {e}") from e
    return out


def _norm(s: str) -> str:
    return re.sub(r"\s+", "", unicodedata.normalize("NFKC", str(s))).lower()


def _iso(s) -> Optional[date]:
    try:
        return date.fromisoformat(str(s)[:10])
    except (TypeError, ValueError):
        return None


def validate_case(case: Mapping, edition: str = "zh") -> list[str]:
    """返回问题列表（空 = 合格）。edition: zh（国内版）| en（国际版）。"""
    p: list[str] = []
    for k in ("id", "skill", "area", "lang", "question", "expect"):
        if not case.get(k):
            p.append(f"missing:{k}")
    if p:
        return p
    if case["area"] not in AREAS:
        p.append(f"bad_area:{case['area']}")
    if case["expect"] not in ("answer", "refuse"):
        p.append(f"bad_expect:{case['expect']}")
    if case["lang"] != edition:
        p.append(f"lang_mismatch:{case['lang']}!={edition}")
    blob = " ".join([case["question"]] + [x if isinstance(x, str) else " ".join(x) for x in case.get("must_include", [])])
    if edition == "en" and CJK.search(blob):
        p.append("cjk_in_english_case")
    if edition == "zh" and not CJK.search(case["question"]):
        p.append("no_cjk_in_chinese_question")
    if case["expect"] == "answer":
        if not case.get("must_include"):
            p.append("answer_case_without_must_include")
        srcs = case.get("sources") or []
        if not srcs:
            p.append("answer_case_without_sources")
        for s in srcs:
            u = urlparse(str(s.get("url", "")))
            if not (u.scheme == "https" or (u.scheme == "http" and (u.hostname or "").endswith(".gov.cn"))):  # 个别政府网站只给 http，其余必须 https
                p.append("source_url_not_https")
            for k in ("title", "issuer", "retrieved_at"):
                if not s.get(k):
                    p.append(f"source_missing:{k}")
            if s.get("retrieved_at") and not _iso(s["retrieved_at"]):
                p.append("source_bad_date")
    if case.get("review_status") in ("已审核", "reviewed") and not case.get("reviewer"):
        p.append("reviewed_without_reviewer")
    if case.get("valid_until") and not _iso(case["valid_until"]):
        p.append("bad_valid_until")
    return p


def validate_all(cases: Iterable[Mapping], edition: str = "zh") -> dict:
    seen, bad, dup = set(), {}, []
    cases = list(cases)
    for c in cases:
        if c.get("id") in seen:
            dup.append(c.get("id"))
        seen.add(c.get("id"))
        pr = validate_case(c, edition)
        if pr:
            bad[c.get("id", "?")] = pr
    return {"n": len(cases), "invalid": bad, "duplicate_ids": dup, "ok": not bad and not dup}


def coverage(cases: Iterable[Mapping], skill_ids: Iterable[str], *, min_cases: int = 2) -> dict:
    cnt: dict[str, int] = {}
    for c in cases:
        cnt[c.get("skill", "?")] = cnt.get(c.get("skill", "?"), 0) + 1
    skills = list(skill_ids)
    return {"counts": {s: cnt.get(s, 0) for s in skills}, "missing": [s for s in skills if cnt.get(s, 0) == 0],
            "thin": [s for s in skills if 0 < cnt.get(s, 0) < min_cases], "unknown_skill_cases": sorted(set(cnt) - set(skills))}


def _includes(text: str, need) -> bool:
    t = _norm(text)
    alts = [need] if isinstance(need, str) else list(need)
    return any(_norm(a) in t for a in alts)


def score_case(case: Mapping, answer) -> dict:
    ans = {"text": answer} if isinstance(answer, str) else dict(answer or {})
    text = str(ans.get("text", ""))
    reasons: list[str] = []
    low = text.lower()
    refused = bool(ans.get("refused")) or any(m in text for m in REFUSAL_ZH) or any(m in low for m in REFUSAL_EN)
    if case["expect"] == "refuse":
        if not refused:
            reasons.append("should_refuse")
    else:
        if ans.get("refused"):
            reasons.append("refused_but_should_answer")
        for need in case.get("must_include", []):
            if not _includes(text, need):
                reasons.append("missing:" + (need if isinstance(need, str) else "|".join(need))[:40])
        cites = ans.get("citations")
        if cites is not None:
            hosts = {urlparse(s["url"]).hostname for s in case.get("sources", [])}
            if not any(urlparse(str(u)).hostname in hosts for u in cites):
                reasons.append("citation_not_from_case_sources")
    nt = _norm(text)
    for bad in case.get("must_not_include", []):
        if _norm(bad) in nt:
            reasons.append("forbidden:" + str(bad)[:40])
    return {"ok": not reasons, "reasons": reasons}


def retrieval_answer_fn(retrieve: Callable[[str, int], list], *, k: int = 8, url_of: Optional[Callable[[Mapping], Optional[str]]] = None):
    """默认“答案”：前 k 个检索片段拼接。测的是知识库有没有覆盖要点，而不是模型的措辞。"""
    def fn(question: str, lang: str) -> dict:
        res = retrieve(question, k) or []
        text = "\n".join(str(r.get("content", "")) for r in res)
        urls = [u for u in ((url_of(r) if url_of else (r.get("metadata") or {}).get("url") or r.get("url")) for r in res) if u]
        return {"text": text, "citations": urls if urls else None}
    return fn


def run_golden(cases: Iterable[Mapping], answer_fn: Callable[[str, str], object], *, edition: str = "zh",
               previous: Optional[Mapping] = None, now: Optional[datetime] = None) -> dict:
    cases = list(cases)
    now = now or datetime.now()
    prev_ok = {i for i, r in (previous or {}).get("results", {}).items() if r.get("ok")}
    results, skipped, by_skill, by_area = {}, {}, {}, {}
    for c in cases:
        pr = validate_case(c, edition)
        if pr:
            skipped[c.get("id", "?")] = pr
            continue
        try:
            ans = answer_fn(c) if getattr(answer_fn, "wants_case", False) else answer_fn(c["question"], c["lang"])
            r = score_case(c, ans)
        except Exception as e:  # noqa: BLE001 — 单题失败不影响其它题
            r = {"ok": False, "reasons": [f"error:{type(e).__name__}"]}
        results[c["id"]] = {**r, "skill": c["skill"], "area": c["area"]}
        for key, bucket in ((c["skill"], by_skill), (c["area"], by_area)):
            b = bucket.setdefault(key, {"n": 0, "passed": 0})
            b["n"] += 1
            b["passed"] += r["ok"]
    for b in list(by_skill.values()) + list(by_area.values()):
        b["rate"] = b["passed"] / b["n"] if b["n"] else 0.0
    n = len(results)
    passed = sum(1 for r in results.values() if r["ok"])
    return {
        "ran_at": now.isoformat(timespec="seconds"), "edition": edition, "n": n, "passed": passed,
        "pass_rate": passed / n if n else 0.0, "by_skill": by_skill, "by_area": by_area,
        "failures": [{"id": i, "skill": r["skill"], "reasons": r["reasons"]} for i, r in results.items() if not r["ok"]],
        "regressions": sorted(i for i, r in results.items() if not r["ok"] and i in prev_ok),
        "skipped_invalid": skipped, "results": results,
    }


def save_result(result: Mapping, data_dir) -> Path:
    d = Path(data_dir) / "golden"
    d.mkdir(parents=True, exist_ok=True)
    day = str(result.get("ran_at", ""))[:10] or date.today().isoformat()
    (d / f"golden_{day}.json").write_text(json.dumps(result, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    p = d / "last.json"
    p.write_text(json.dumps(result, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    return p


def load_last(data_dir) -> Optional[dict]:
    p = Path(data_dir) / "golden" / "last.json"
    return json.loads(p.read_text("utf-8")) if p.exists() else None


def load_month(data_dir, month: str) -> list[dict]:
    d = Path(data_dir) / "golden"
    return [json.loads(p.read_text("utf-8")) for p in sorted(d.glob(f"golden_{month}-*.json"))] if d.exists() else []
