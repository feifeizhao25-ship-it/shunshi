"""用户记忆/养生报告导出: PDF (reportlab) + Word (.docx, 标准库 zip) + Markdown.

在原有 JSON 导出 (router/memory.py /export) 之上补可读报告格式。
PDF 中文字体: 依次找环境变量 SHUNSHI_REPORT_FONT、系统 STHeiti/PingFang;
找不到 CJK 字体时明确报错, 不生成乱码 PDF。报告只汇总用户自己的记忆数据,
不含诊断/处方/疗效内容。
"""
from __future__ import annotations
import io, os, zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape

def _report_lines(user_id: str, memories: list) -> list:
    lines = ["顺时 · 我的养生记忆报告", f"用户: {user_id}", f"导出时间: {datetime.now(timezone.utc).isoformat()}", f"共 {len(memories)} 条记录", ""]
    for m in memories:
        lines.append(f"[{m.get('type') or m.get('memory_type') or '记录'}] {m.get('content','')}")
        if m.get("created_at"):
            lines.append(f"  记录时间: {m['created_at']}")
    lines += ["", "说明: 本报告仅汇总您在顺时中保存的生活记录, 不构成医疗诊断或用药建议。"]
    return lines

def build_markdown(user_id: str, memories: list) -> bytes:
    lines = _report_lines(user_id, memories)
    md = ["# " + lines[0], ""] + [f"- {l}" if l.startswith("[") else l for l in lines[1:]]
    return "\n".join(md).encode("utf-8")

def build_docx(user_id: str, memories: list) -> bytes:
    lines = _report_lines(user_id, memories)
    paras = "".join(f'<w:p><w:r><w:t xml:space="preserve">{escape(l)}</w:t></w:r></w:p>' for l in lines)
    document = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + paras + '</w:body></w:document>')
    content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>')
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("word/document.xml", document)
    return buf.getvalue()

# Noto Sans SC（SIL Open Font License 1.1），简体子集，TrueType。
# 仓库里的 NotoSansCJKsc-Regular.otf 是 PostScript 轮廓，reportlab 画不了。
_BUNDLED_FONT = Path(__file__).resolve().parent.parent / "assets" / "fonts" / "NotoSansSC-Regular.ttf"
_FONT_CANDIDATES = [
    str(_BUNDLED_FONT),
    "/System/Library/Fonts/STHeiti Medium.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/PingFang.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
]

def _cjk_font_path():
    env = os.environ.get("SHUNSHI_REPORT_FONT")
    for cand in ([env] if env else []) + _FONT_CANDIDATES:
        if cand and os.path.exists(cand):
            return cand
    return None

def build_pdf(user_id: str, memories: list) -> bytes:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    font_path = _cjk_font_path()
    if not font_path:
        raise RuntimeError("服务器未找到中文字体 (可设置 SHUNSHI_REPORT_FONT), 无法生成中文 PDF")
    pdfmetrics.registerFont(TTFont("ShunShiCJK", font_path, subfontIndex=0))
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    c.setFont("ShunShiCJK", 13)
    y = A4[1] - 56
    for line in _report_lines(user_id, memories):
        # 简单按宽折行
        text = line
        while text:
            chunk, text = text[:60], text[60:]
            c.drawString(48, y, chunk); y -= 20
            if y < 56:
                c.showPage(); c.setFont("ShunShiCJK", 13); y = A4[1] - 56
    c.showPage(); c.save()
    return buf.getvalue()
