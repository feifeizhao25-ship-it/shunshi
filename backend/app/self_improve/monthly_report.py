"""每月改进报告（Markdown + 可选 PDF + JSON）：改了什么、评测分数、陈旧项、等人审核的候选。

纯汇总：只读 SIL/资料库已有的文件，不联网、不改任何内容、不发送给任何人（产出文件由人转发）。
SIL 关闭时照样可以手动生成（报告里会写明“自改进未开启，本月没有自动改动”）。
PDF 用 reportlab（没装就只出 Markdown 和 JSON，并在结果里写明原因）；中文字体顺序：
SIL_REPORT_FONT（.ttf 路径）→ 系统常见 TrueType 中文字体 → reportlab 内置 CID 字体 STSong-Light（不嵌入，依赖阅读器的中文字体）。
"""

from __future__ import annotations

import json
import os
from datetime import date
from pathlib import Path
from typing import Iterable, Mapping, Optional

I18N = {
    "zh": {
        "title": "{product} - 月度改进报告 - {month}", "overview": "一、概览", "changes": "二、本月改了什么", "scores": "三、评测分数（金标准问答）",
        "stale": "四、陈旧内容（需要复核）", "awaiting": "五、等人审核的候选", "radar": "六、研究雷达", "next": "七、下月建议",
        "sil_off": "自改进（SIL）目前是关闭状态：本月没有任何自动改动，下面的“改动”只来自人工审核操作。",
        "sil_on": "自改进（SIL）已开启；任何用户可见的改动都必须经过人工批准。",
        "k_pass": "金标准通过率", "k_prev": "上月", "k_reg": "退步题数", "k_stale": "高优先级陈旧项", "k_wait": "等人审核", "k_n": "题数",
        "none": "（本月没有）", "skill": "技能/主题", "rate": "通过率", "delta": "变化", "n": "题数", "kind": "类型", "id": "编号", "reason": "原因",
        "sev": "优先级", "action": "状态", "when": "时间", "what": "内容", "who": "操作人", "license": "许可证类别", "link": "链接",
        "digests": "本月雷达摘要 {n} 份，累计新线索 {m} 条（全部是未核线索，没有入库）。", "staged": "已暂存的资料库候选线索 {n} 条（全部待审核、不可见、不会自动通过）。",
        "no_golden": "本月没有金标准评测记录（评测任务未开启或未运行）。", "generated": "生成日期 {d}。本报告只汇总已有文件，没有联网、没有改任何内容。",
        "reg_h": "退步的题（上次通过、这次没通过）", "fail_h": "没通过的题", "adv_none": "没有需要特别处理的事项。",
        "adv_reg": "先看 {n} 道退步的题：{ids}", "adv_stale": "先处理 {n} 个高优先级陈旧项（过期/被取代/没有出处）", "adv_wait": "有 {n} 个候选在等人审核；超过 45 天没人看的会被标成陈旧",
        "adv_skill": "这些技能/主题通过率低于 90%：{names}", "adv_off": "SIL 与评测任务仍是关闭状态；要启用由你决定，并先填好审批人名单",
        "pdf_missing": "PDF 未生成：{why}",
    },
    "en": {
        "title": "{product} - Monthly improvement report - {month}", "overview": "1. Overview", "changes": "2. What changed this month", "scores": "3. Evaluation scores (golden Q&A)",
        "stale": "4. Stale content (needs review)", "awaiting": "5. Candidates awaiting human review", "radar": "6. Research radar", "next": "7. Suggestions for next month",
        "sil_off": "Self-improvement (SIL) is switched off: nothing changed automatically this month; the changes below come from manual review actions only.",
        "sil_on": "Self-improvement (SIL) is on; every user-visible change still needs human approval.",
        "k_pass": "Golden pass rate", "k_prev": "Last month", "k_reg": "Regressions", "k_stale": "High-priority stale items", "k_wait": "Awaiting review", "k_n": "Cases",
        "none": "(none this month)", "skill": "Skill / topic", "rate": "Pass rate", "delta": "Change", "n": "Cases", "kind": "Type", "id": "ID", "reason": "Reason",
        "sev": "Priority", "action": "State", "when": "When", "what": "What", "who": "By", "license": "License class", "link": "Link",
        "digests": "{n} radar digests this month, {m} new leads in total (all unverified leads; nothing was ingested).", "staged": "{n} staged library candidate leads (all pending review, hidden, never auto-approved).",
        "no_golden": "No golden evaluation runs this month (the job is off or did not run).", "generated": "Generated on {d}. This report only summarises existing files: no network access, no content changed.",
        "reg_h": "Regressions (passed last time, failing now)", "fail_h": "Failing cases", "adv_none": "Nothing needs special attention.",
        "adv_reg": "Look at the {n} regressed cases first: {ids}", "adv_stale": "Handle {n} high-priority stale items first (expired / superseded / no source)", "adv_wait": "{n} candidates are waiting for review; items unseen for 45+ days are flagged stale",
        "adv_skill": "These skills/topics are below 90%: {names}", "adv_off": "SIL and the evaluation jobs are still off; turning them on is your call, after the approver list is filled in",
        "pdf_missing": "PDF not generated: {why}",
    },
}


def _month_of(s: str) -> str:
    return str(s)[:7]


def build_report(product: str, month: str, *, golden_runs: Iterable[Mapping] = (), previous_golden: Optional[Mapping] = None,
                 ledger_events: Iterable[Mapping] = (), review_log: Iterable[Mapping] = (), stale: Optional[Mapping] = None,
                 candidates: Iterable[Mapping] = (), staged: Iterable[Mapping] = (), pending_entries: int = 0,
                 radar_digests: int = 0, radar_new_items: int = 0, sil_enabled: bool = False, lang: str = "zh",
                 today: Optional[date] = None) -> dict:
    t = I18N[lang]
    runs = list(golden_runs)
    last = runs[-1] if runs else None
    changes = []
    for ev in ledger_events:
        e = ev.get("event", ev)
        if _month_of(e.get("t", "")) == month and e.get("to") in ("promoted", "rolled_back", "rejected", "approved", "expired"):
            changes.append({"when": str(e.get("t", ""))[:10], "what": f"{e.get('kind', '')} {e.get('target', e.get('id', ''))} → {e.get('to')}", "who": e.get("reviewer", "")})
    for r in review_log:
        if _month_of(r.get("at", r.get("t", r.get("date", "")))) == month:
            changes.append({"when": str(r.get("at", r.get("t", r.get("date", ""))))[:10], "what": f"{r.get('action', '')} {r.get('id', r.get('entry_id', ''))} {r.get('note', '')}".strip(), "who": r.get("reviewer", "")})
    changes.sort(key=lambda c: c["when"])
    skills = []
    if last:
        prev = (previous_golden or {}).get("by_skill", {})
        for s, b in sorted(last["by_skill"].items(), key=lambda kv: kv[1]["rate"]):
            pr = prev.get(s, {}).get("rate")
            skills.append({"skill": s, "n": b["n"], "rate": b["rate"], "prev": pr, "delta": (b["rate"] - pr) if pr is not None else None})
    cands = [dict(c) for c in candidates if c.get("state") in ("pending_approval", "quarantined", "evaluated")]
    staged = list(staged)
    findings = (stale or {}).get("findings", [])
    high = [f for f in findings if f["severity"] == "high"]
    waiting = len(cands) + len(staged) + pending_entries
    advice = []
    if last and last.get("regressions"):
        advice.append(t["adv_reg"].format(n=len(last["regressions"]), ids=", ".join(last["regressions"][:8])))
    if high:
        advice.append(t["adv_stale"].format(n=len(high)))
    if waiting:
        advice.append(t["adv_wait"].format(n=waiting))
    low = [s["skill"] for s in skills if s["rate"] < 0.9]
    if low:
        advice.append(t["adv_skill"].format(names=", ".join(low[:8])))
    if not sil_enabled:
        advice.append(t["adv_off"])
    if not advice:
        advice.append(t["adv_none"])
    return {
        "product": product, "month": month, "lang": lang, "generated": (today or date.today()).isoformat(), "sil_enabled": sil_enabled,
        "golden": None if not last else {"n": last["n"], "passed": last["passed"], "pass_rate": last["pass_rate"], "ran_at": last["ran_at"],
                                          "prev_pass_rate": (previous_golden or {}).get("pass_rate"), "regressions": last.get("regressions", []),
                                          "failures": last.get("failures", [])},
        "skills": skills, "changes": changes, "stale": {"counts": (stale or {}).get("counts", {}), "high": len(high), "findings": findings},
        "awaiting": {"candidates": cands, "staged": staged, "pending_entries": pending_entries, "total": waiting},
        "radar": {"digests": radar_digests, "new_items": radar_new_items}, "advice": advice,
    }


def _pct(x) -> str:
    return "—" if x is None else f"{x * 100:.1f}%"


def _md_table(head: list[str], rows: list[list[str]]) -> list[str]:
    if not rows:
        return []
    esc = lambda s: str(s).replace("|", "/").replace("\n", " ")  # noqa: E731
    return ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)] + ["| " + " | ".join(esc(c) for c in r) + " |" for r in rows] + [""]


def sections(rep: Mapping) -> list[tuple[str, list]]:
    """(标题, 块列表)；块 = ("p", 文本) | ("table", 表头, 行) | ("kv", [(k, v)]) | ("bullets", [文本])。Markdown 与 PDF 共用。"""
    t = I18N[rep["lang"]]
    g = rep["golden"]
    out: list[tuple[str, list]] = []
    kv = [(t["k_pass"], _pct(g["pass_rate"]) if g else "—"), (t["k_prev"], _pct(g["prev_pass_rate"]) if g else "—"), (t["k_n"], str(g["n"]) if g else "0"),
          (t["k_reg"], str(len(g["regressions"])) if g else "0"), (t["k_stale"], str(rep["stale"]["high"])), (t["k_wait"], str(rep["awaiting"]["total"]))]
    out.append((t["overview"], [("p", t["sil_on"] if rep["sil_enabled"] else t["sil_off"]), ("kv", kv)]))
    ch = rep["changes"]
    out.append((t["changes"], [("table", [t["when"], t["what"], t["who"]], [[c["when"], c["what"], c["who"] or "—"] for c in ch])] if ch else [("p", t["none"])]))
    sc = []
    if not g:
        sc.append(("p", t["no_golden"]))
    else:
        sc.append(("table", [t["skill"], t["n"], t["rate"], t["k_prev"], t["delta"]],
                   [[s["skill"], str(s["n"]), _pct(s["rate"]), _pct(s["prev"]), "—" if s["delta"] is None else f"{s['delta'] * 100:+.1f}pt"] for s in rep["skills"]]))
        if g["regressions"]:
            sc.append(("p", t["reg_h"] + "：" + ", ".join(g["regressions"])))
        if g["failures"]:
            sc.append(("p", t["fail_h"]))
            sc.append(("table", [t["id"], t["skill"], t["reason"]], [[f["id"], f["skill"], ", ".join(f["reasons"])] for f in g["failures"][:40]]))
    out.append((t["scores"], sc))
    fs = rep["stale"]["findings"]
    out.append((t["stale"], [("table", [t["sev"], t["kind"], t["id"], t["reason"]], [[f["severity"], f["kind"], f["id"], f["reason"]] for f in fs[:40]])] if fs else [("p", t["none"])]))
    aw = rep["awaiting"]
    ab: list = []
    if aw["candidates"]:
        ab.append(("table", [t["id"], t["what"], t["action"]], [[c.get("id", ""), c.get("summary", c.get("target", "")), c.get("state", "")] for c in aw["candidates"]]))
    if aw["staged"]:
        ab.append(("p", t["staged"].format(n=len(aw["staged"]))))
        ab.append(("table", [t["id"], t["what"], t["license"], t["link"]], [[s.get("id", ""), s.get("title", ""), s.get("license_class", ""), s.get("url", "")] for s in aw["staged"][:30]]))
    if aw["pending_entries"]:
        ab.append(("p", f"{t['k_wait']}（library）: {aw['pending_entries']}"))
    out.append((t["awaiting"], ab or [("p", t["none"])]))
    out.append((t["radar"], [("p", t["digests"].format(n=rep["radar"]["digests"], m=rep["radar"]["new_items"]))]))
    out.append((t["next"], [("bullets", rep["advice"])]))
    return out


def render_markdown(rep: Mapping) -> str:
    t = I18N[rep["lang"]]
    lines = [f"# {t['title'].format(product=rep['product'], month=rep['month'])}", ""]
    for title, blocks in sections(rep):
        lines += [f"## {title}", ""]
        for b in blocks:
            if b[0] == "p":
                lines += [b[1], ""]
            elif b[0] == "kv":
                lines += _md_table(["", ""], [[k, v] for k, v in b[1]])
            elif b[0] == "table":
                lines += _md_table(b[1], b[2])
            elif b[0] == "bullets":
                lines += [f"- {x}" for x in b[1]] + [""]
    lines.append(f"_{t['generated'].format(d=rep['generated'])}_")
    return "\n".join(lines) + "\n"


_FONT_CANDIDATES = (
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf", "/usr/share/fonts/truetype/wqy/wqy-microhei.ttf",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttf", "/usr/share/fonts/truetype/arphic/uming.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansSC-Regular.ttf", "/usr/share/fonts/noto-cjk/NotoSansSC-Regular.ttf",
)


def _register_font(env=None) -> str:
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.cidfonts import UnicodeCIDFont
    from reportlab.pdfbase.ttfonts import TTFont

    env = os.environ if env is None else env
    for path in [env.get("SIL_REPORT_FONT", "")] + list(_FONT_CANDIDATES):
        if path and Path(path).exists() and path.lower().endswith(".ttf"):
            try:
                pdfmetrics.registerFont(TTFont("SILCJK", path))
                return "SILCJK"
            except Exception:  # noqa: BLE001 — 换下一个
                continue
    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))
    return "STSong-Light"


def render_pdf(rep: Mapping, path, *, env=None) -> Optional[str]:
    """成功返回路径；reportlab 不可用返回 None（调用方把原因写进结果）。"""
    try:
        from reportlab.lib import colors
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.styles import ParagraphStyle
        from reportlab.lib.units import mm
        from reportlab.platypus import ListFlowable, ListItem, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
    except ImportError:
        return None
    font = _register_font(env)
    t = I18N[rep["lang"]]
    base = ParagraphStyle("b", fontName=font, fontSize=9.5, leading=14, wordWrap="CJK")
    cell = ParagraphStyle("c", parent=base, fontSize=8.5, leading=11.5)
    h1 = ParagraphStyle("h1", parent=base, fontSize=19, leading=26, spaceAfter=6, textColor=colors.HexColor("#1f3a5f"))
    h2 = ParagraphStyle("h2", parent=base, fontSize=13, leading=18, spaceBefore=12, spaceAfter=5, textColor=colors.HexColor("#1f3a5f"))
    esc = lambda s: str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")  # noqa: E731
    story = [Paragraph(esc(t["title"].format(product=rep["product"], month=rep["month"])), h1)]
    width = A4[0] - 36 * mm

    def table(head, rows, widths=None):
        data = [[Paragraph(f"<b>{esc(h)}</b>", cell) for h in head]] + [[Paragraph(esc(c), cell) for c in r] for r in rows]
        w = widths or [width / len(head)] * len(head)
        tb = Table(data, colWidths=w, repeatRows=1)
        tb.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e8eef6")), ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#b8c4d4")),
                                ("VALIGN", (0, 0), (-1, -1), "TOP"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7f9fc")])]))
        return tb

    for title, blocks in sections(rep):
        story.append(Paragraph(esc(title), h2))
        for b in blocks:
            if b[0] == "p":
                story += [Paragraph(esc(b[1]), base), Spacer(1, 3)]
            elif b[0] == "kv":
                cards = [[Paragraph(f"<font size=8 color='#667'>{esc(k)}</font><br/><font size=15><b>{esc(v)}</b></font>", base) for k, v in b[1][i:i + 3]] for i in range(0, len(b[1]), 3)]
                tb = Table(cards, colWidths=[width / 3] * 3)
                tb.setStyle(TableStyle([("BOX", (0, 0), (-1, -1), 0.4, colors.HexColor("#b8c4d4")), ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d5dde8")),
                                        ("TOPPADDING", (0, 0), (-1, -1), 7), ("BOTTOMPADDING", (0, 0), (-1, -1), 7), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f4f7fb"))]))
                story += [tb, Spacer(1, 4)]
            elif b[0] == "table":
                story += [table(b[1], b[2]), Spacer(1, 5)]
            elif b[0] == "bullets":
                story.append(ListFlowable([ListItem(Paragraph(esc(x), base)) for x in b[1]], bulletType="bullet", leftIndent=12))
    story.append(Spacer(1, 8))
    story.append(Paragraph(f"<font size=8 color='#667'>{esc(t['generated'].format(d=rep['generated']))}</font>", base))

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont(font, 8)
        canvas.setFillColor(colors.HexColor("#889"))
        canvas.drawRightString(A4[0] - 18 * mm, 10 * mm, f"{rep['product']} - {rep['month']} - {doc.page}")
        canvas.restoreState()

    Path(path).parent.mkdir(parents=True, exist_ok=True)
    SimpleDocTemplate(str(path), pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=18 * mm,
                      title=t["title"].format(product=rep["product"], month=rep["month"])).build(story, onFirstPage=footer, onLaterPages=footer)
    return str(path)


def write_all(rep: Mapping, out_dir, *, env=None) -> dict:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    stem = f"monthly-{rep['month']}"
    (out / f"{stem}.json").write_text(json.dumps(rep, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    (out / f"{stem}.md").write_text(render_markdown(rep), "utf-8")
    pdf = None
    why = ""
    try:
        pdf = render_pdf(rep, out / f"{stem}.pdf", env=env)
        if pdf is None:
            why = "reportlab not installed"
    except Exception as e:  # noqa: BLE001 — PDF 失败不影响 Markdown/JSON
        why = type(e).__name__
    return {"markdown": str(out / f"{stem}.md"), "json": str(out / f"{stem}.json"), "pdf": pdf,
            "pdf_note": I18N[rep["lang"]]["pdf_missing"].format(why=why) if pdf is None else ""}
