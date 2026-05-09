#!/usr/bin/env python3
"""
顺时 ShunShi — 全量 API 测试套件
测试所有关键 API 端点的可用性、响应时间和输出质量
"""
import json
import time
import sys
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

BASE_URL = "http://localhost:4000"
RESULTS = []


def call_api(method, path, data=None, headers=None, timeout=30):
    """调用 API 并返回结果"""
    url = f"{BASE_URL}{path}"
    req_headers = headers or {}
    req_headers.setdefault("Content-Type", "application/json")
    
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, headers=req_headers, method=method)
    
    start = time.time()
    try:
        resp = urlopen(req, timeout=timeout)
        status = resp.status
        body_text = resp.read().decode()
        latency = (time.time() - start) * 1000
        try:
            body_json = json.loads(body_text)
        except:
            body_json = None
        return {"status": status, "latency_ms": round(latency, 1), 
                "body": body_json or body_text[:500], "error": None}
    except HTTPError as e:
        latency = (time.time() - start) * 1000
        body_text = e.read().decode() if e.read() else ""
        return {"status": e.code, "latency_ms": round(latency, 1), 
                "body": body_text[:500], "error": str(e)}
    except URLError as e:
        latency = (time.time() - start) * 1000
        return {"status": 0, "latency_ms": round(latency, 1), 
                "body": None, "error": str(e)}
    except Exception as e:
        latency = (time.time() - start) * 1000
        return {"status": 0, "latency_ms": round(latency, 1), 
                "body": None, "error": str(e)}


def test(name, method, path, data=None, headers=None, expect_success=True, timeout=30):
    """运行单个测试"""
    print(f"\n{'='*60}")
    print(f"TEST: {name}")
    print(f"{method} {path}")
    if data:
        print(f"Body: {json.dumps(data, ensure_ascii=False)[:200]}")
    
    result = call_api(method, path, data, headers)
    
    success = result["status"] == 200 if expect_success else result["status"] < 500
    status_str = f"{result['status']}" if result['status'] else "CONN_ERR"
    
    print(f"Status: {status_str} | Latency: {result['latency_ms']}ms")
    
    if result["error"]:
        print(f"Error: {result['error'][:200]}")
    
    if result["body"]:
        body_preview = json.dumps(result["body"], ensure_ascii=False)[:500] if isinstance(result["body"], dict) else str(result["body"])[:500]
        print(f"Response: {body_preview}")
    
    RESULTS.append({
        "name": name,
        "path": path,
        "method": method,
        "status": result["status"],
        "latency_ms": result["latency_ms"],
        "success": success,
        "error": result["error"],
    })
    
    return result


def main():
    print("=" * 60)
    print("  顺时 ShunShi — API 全量测试")
    print(f"  Base URL: {BASE_URL}")
    print(f"  Time: {datetime.now().isoformat()}")
    print("=" * 60)
    
    # ========== 1. 基础健康检查 ==========
    print("\n" + "-" * 40)
    print("GROUP 1: 健康检查")
    print("-" * 40)
    
    test("Health Basic", "GET", "/health")
    test("Health Detailed", "GET", "/api/v1/health/detailed")
    test("Health Ready", "GET", "/api/v1/health/ready")
    test("Health Live", "GET", "/api/v1/health/live")
    
    # ========== 2. 认证 API ==========
    print("\n" + "-" * 40)
    print("GROUP 2: 认证")
    print("-" * 40)
    
    auth_result = test("Guest Login", "POST", "/api/v1/auth/login", 
                      {"email": "test@shunshi.cn", "password": "test123"})
    token = None
    if auth_result.get("body") and isinstance(auth_result["body"], dict):
        token = auth_result["body"].get("data", {}).get("token")
    
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    test("Get Me", "GET", "/api/v1/auth/me", headers=headers)
    
    # ========== 3. 核心 Skills ==========
    print("\n" + "-" * 40)
    print("GROUP 3: 核心 Skills")
    print("-" * 40)
    
    test("Skills List", "GET", "/api/v1/core-skills/list")
    
    # 测试几个关键 skill（注意：这些会调用 LLM，可能较慢）
    skill_tests = [
        ("daily_rhythm", {"user_context": {"time_of_day": "morning"}, "signals": {}}),
        ("solar_term", {"user_context": {}, "signals": {}}),
        ("body_constitution", {"user_context": {}, "signals": {}}),
        ("mood_first_aid", {"user_context": {"mood": "stressed"}, "signals": {}}),
    ]
    
    for skill_name, input_data in skill_tests[:2]:  # 只测2个避免太慢
        test(f"Skill: {skill_name}", "POST", "/api/v1/core-skills/run",
             {"skill_name": skill_name, "input": input_data}, headers=headers, timeout=60)
    
    # ========== 4. RAG 系统 ==========
    print("\n" + "-" * 40)
    print("GROUP 4: RAG 知识库")
    print("-" * 40)
    
    test("RAG Status", "GET", "/api/v1/rag/status")
    test("RAG Query", "POST", "/api/v1/rag/query",
         {"query": "春季养生吃什么好？", "top_k": 3}, timeout=45)
    test("RAG Query (Global)", "POST", "/api/v1/rag/query",
         {"query": "What to eat in spring for wellness?", "locale": "en"}, timeout=45)
    
    # ========== 5. 节气/内容 ==========
    print("\n" + "-" * 40)
    print("GROUP 5: 节气与内容")
    print("-" * 40)
    
    test("Current Solar Term", "GET", "/api/v1/seasons/season/current")
    test("Solar Terms List", "GET", "/api/v1/solar-terms")
    test("Contents List", "GET", "/api/v1/contents")
    test("Recommendations", "GET", "/api/v1/recommendations?user_id=user-001")
    
    # ========== 6. 订阅/支付 ==========
    print("\n" + "-" * 40)
    print("GROUP 6: 订阅系统")
    print("-" * 40)
    
    test("Subscription Plans", "GET", "/api/v1/subscription/plans?user_id=user-001")
    test("Subscription Products", "GET", "/api/v1/subscription/products?user_id=user-001")
    
    # ========== 7. 家庭/用户 ==========
    print("\n" + "-" * 40)
    print("GROUP 7: 家庭与用户")
    print("-" * 40)
    
    test("Family Info", "GET", "/api/v1/family?user_id=user-001")
    test("User Settings", "GET", "/api/v1/settings?user_id=user-001")
    
    # ========== 8. 管理后台 ==========
    print("\n" + "-" * 40)
    print("GROUP 8: Admin & 审计")
    print("-" * 40)
    
    test("Feature Flags", "GET", "/api/v1/flags")
    test("Audit Logs", "GET", "/api/v1/admin/audit/recent")
    
    # ========== 9. 推送/通知 ==========
    print("\n" + "-" * 40)
    print("GROUP 9: 推送通知")
    print("-" * 40)
    
    test("Notifications Register", "POST", "/api/v1/notifications/register-token",
         {"user_id": "user-001", "token": "test-token", "platform": "android"})
    test("Notifications Unread", "GET", "/api/v1/notifications/unread-count?user_id=user-001")
    
    # ========== 10. 数据合规 ==========
    print("\n" + "-" * 40)
    print("GROUP 10: 数据合规")
    print("-" * 40)
    
    test("Privacy Policy", "GET", "/static/privacy-policy.html", expect_success=False)
    test("Medical Disclaimer", "GET", "/static/medical-disclaimer.html", expect_success=False)
    
    # ========== 汇总 ==========
    print("\n" + "=" * 60)
    print("  测试结果汇总")
    print("=" * 60)
    
    total = len(RESULTS)
    passed = sum(1 for r in RESULTS if r["success"])
    failed = total - passed
    avg_latency = sum(r["latency_ms"] for r in RESULTS if r["status"] > 0) / max(1, sum(1 for r in RESULTS if r["status"] > 0))
    
    # 按状态分类
    http_200 = [r for r in RESULTS if r["status"] == 200]
    http_4xx = [r for r in RESULTS if 400 <= r["status"] < 500]
    http_5xx = [r for r in RESULTS if r["status"] >= 500]
    conn_err = [r for r in RESULTS if r["status"] == 0]
    
    print(f"\n总计: {total} 个测试")
    print(f"通过: {passed} ({passed/total*100:.0f}%)")
    print(f"失败: {failed} ({failed/total*100:.0f}%)")
    print(f"平均延迟: {avg_latency:.0f}ms")
    
    print(f"\nHTTP 200: {len(http_200)}")
    print(f"HTTP 4xx: {len(http_4xx)}")
    print(f"HTTP 5xx: {len(http_5xx)}")
    print(f"连接错误: {len(conn_err)}")
    
    print(f"\n{'-'*60}")
    print("失败详情:")
    for r in RESULTS:
        if not r["success"]:
            print(f"  ✗ {r['name']} — {r['method']} {r['path']} → {r['status']} ({r['latency_ms']}ms)")
            if r["error"]:
                print(f"    Error: {r['error'][:100]}")
    
    print(f"\n{'-'*60}")
    print("慢查询 (>1000ms):")
    for r in RESULTS:
        if r["latency_ms"] > 1000:
            print(f"  ⚠ {r['name']} — {r['latency_ms']}ms")
    
    # 输出 JSON 报告
    report = {
        "timestamp": datetime.now().isoformat(),
        "summary": {
            "total": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": round(passed/total*100, 1),
            "avg_latency_ms": round(avg_latency, 1),
        },
        "results": RESULTS,
    }
    
    with open("/tmp/shunshi-api-test-report.json", "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print(f"\n详细报告已保存: /tmp/shunshi-api-test-report.json")
    
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
