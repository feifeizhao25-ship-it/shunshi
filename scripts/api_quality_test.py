#!/usr/bin/env python3
"""
顺时 ShunShi — API 质量与性能测试
测试 Skills、RAG、Chat 的实际输出，记录速度和质量
"""
import json
import time
import urllib.request
import urllib.error
from datetime import datetime

BASE = "http://localhost:4000"
RESULTS = []

def call(method, path, data=None, timeout=120):
    url = f"{BASE}{path}"
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode() if data else None,
        headers={"Content-Type": "application/json"},
        method=method,
    )
    t0 = time.time()
    try:
        resp = urllib.request.urlopen(req, timeout=timeout)
        body = json.loads(resp.read().decode())
        return {"ok": True, "status": resp.status, "latency_ms": round((time.time()-t0)*1000,1), "body": body}
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try: body = json.loads(body)
        except: pass
        return {"ok": False, "status": e.code, "latency_ms": round((time.time()-t0)*1000,1), "body": body}
    except Exception as e:
        return {"ok": False, "status": 0, "latency_ms": round((time.time()-t0)*1000,1), "body": str(e)}

def test(name, method, path, data=None, timeout=120):
    import time
    time.sleep(1.5)  # 避免触发限流
    print(f"\n{'='*60}\nTEST: {name}\n{method} {path}")
    r = call(method, path, data, timeout)
    status = "✓" if r["ok"] else "✗"
    print(f"{status} {r['status']} | {r['latency_ms']}ms")
    if isinstance(r["body"], dict):
        preview = json.dumps(r["body"], ensure_ascii=False)[:800]
    else:
        preview = str(r["body"])[:400]
    print(f"Response: {preview}")
    RESULTS.append({"name": name, "path": path, **r})
    return r

print("="*60)
print("顺时 ShunShi — API 质量与性能测试")
print(f"Time: {datetime.now().isoformat()}")
print("="*60)

# 1. 健康检查
test("Health", "GET", "/api/v1/health/detailed")

# 2. Skills 列表
test("Skills List", "GET", "/api/v1/core-skills/list")

# 3. Skill Run — DailyRhythmPlan (调用 DeepSeek v4)
test("Skill: DailyRhythmPlan", "POST", "/api/v1/core-skills/run", {
    "skill": "DailyRhythmPlan",
    "user_id": "user-001",
    "user_context": {"life_stage": "adult", "time_of_day": "morning"},
    "task_params": {"date": "2026-04-29"},
    "signals": {"sleep_quality": "good", "mood": "calm"},
    "locale": "zh-CN"
}, timeout=120)

# 4. Skill Run — SolarTermGuide
test("Skill: SolarTermGuide", "POST", "/api/v1/core-skills/run", {
    "skill": "SolarTermGuide",
    "user_id": "user-001",
    "user_context": {},
    "task_params": {},
    "locale": "zh-CN"
}, timeout=120)

# 5. Skill Chat — 智能路由
test("Skill Chat", "POST", "/api/v1/core-skills/chat", {
    "user_id": "user-001",
    "message": "我晚上总是睡不着，有什么建议？",
    "user_context": {"life_stage": "adult"},
    "locale": "zh-CN"
}, timeout=120)

# 6. RAG Query — 中文
test("RAG: 中文查询", "POST", "/api/v1/rag/query", {
    "query": "春季养生应该吃什么？",
    "top_k": 3,
    "locale": "zh-CN"
}, timeout=60)

# 7. RAG Query — 英文
test("RAG: English Query", "POST", "/api/v1/rag/query/semantic", {
    "query": "What foods are good for spring wellness?",
    "lang": "gl",
    "top_k": 3
}, timeout=60)

# 8. RAG Hybrid
test("RAG: Hybrid", "POST", "/api/v1/rag/query/hybrid", {
    "query": "失眠怎么办",
    "top_k": 3
}, timeout=60)

# 9. 节气当前
test("Solar Term Current", "GET", "/api/v1/seasons/season/current")

# 10. 聊天 (主聊天 API)
test("Chat API", "POST", "/api/v1/chat", {
    "user_id": "user-001",
    "message": "你好，今天感觉有些疲劳",
    "conversation_id": None
}, timeout=120)

# 11. 体质测试
test("Constitution", "POST", "/api/v1/constitution/analyze", {
    "user_id": "user-001",
    "answers": {"q1": "a", "q2": "b", "q3": "c"}
}, timeout=60)

# 12. 订阅计划
test("Subscription Plans", "GET", "/api/v1/subscription/plans?user_id=user-001")

# 汇总
print("\n" + "="*60)
print("测试结果汇总")
print("="*60)

total = len(RESULTS)
passed = sum(1 for r in RESULTS if r["ok"])
avg_lat = sum(r["latency_ms"] for r in RESULTS if r["ok"]) / max(1, passed)
llm_calls = [r for r in RESULTS if r["name"] in ["Skill: DailyRhythmPlan", "Skill: SolarTermGuide", "Skill Chat", "Chat API"]]

print(f"\n总计: {total} | 通过: {passed} | 失败: {total-passed}")
print(f"平均延迟: {avg_lat:.0f}ms")
print(f"\nLLM 调用测试 ({len(llm_calls)} 个):")
for r in llm_calls:
    status = "✓" if r["ok"] else "✗"
    print(f"  {status} {r['name']:30s} — {r['latency_ms']:6.0f}ms — HTTP {r['status']}")

print(f"\n慢查询 (>3000ms):")
for r in RESULTS:
    if r["latency_ms"] > 3000:
        print(f"  ⚠ {r['name']} — {r['latency_ms']:.0f}ms")

# 保存报告
report = {
    "timestamp": datetime.now().isoformat(),
    "summary": {"total": total, "passed": passed, "avg_latency_ms": round(avg_lat,1)},
    "results": RESULTS,
}
with open("/tmp/shunshi-quality-test.json", "w") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)
print(f"\n报告已保存: /tmp/shunshi-quality-test.json")
