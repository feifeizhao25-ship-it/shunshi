#!/usr/bin/env python3
"""ShunShi Domestic CN — Comprehensive API Test with Full Output"""
import json
import time
import requests

API = "http://localhost:8000/api/v1"
s = requests.Session()
results = []

def log(cat, method, endpoint, resp, persona=""):
    entry = {"category": cat, "persona": persona, "method": method, "endpoint": endpoint,
             "status": resp.status_code, "duration_ms": 0, "response": resp.json() if resp.headers.get("content-type","").startswith("application/json") else resp.text[:500]}
    results.append(entry)
    ok = "✅" if resp.status_code < 300 else f"⚠️({resp.status_code})"
    print(f"  {ok} {method} {endpoint}")
    return entry

def auth(phone, pwd, nickname):
    r = s.post(f"{API}/auth/signup", json={"phone": phone, "password": pwd, "nickname": nickname}, timeout=10)
    time.sleep(0.3)
    r = s.post(f"{API}/auth/login", json={"phone": phone, "password": pwd}, timeout=10)
    time.sleep(0.3)
    if r.status_code != 200:
        r = s.post(f"{API}/auth/dev-token", timeout=10)
    token = r.json().get("access_token", "")
    s.headers.update({"Authorization": f"Bearer {token}"})
    return token

def get(path, **params):
    time.sleep(0.15)
    return s.get(f"{API}{path}", params=params, timeout=30)

def post(path, data):
    time.sleep(0.15)
    return s.post(f"{API}{path}", json=data, timeout=120)

print("="*80)
print("🇨🇳 国内版 DOMESTIC — 8用户画像全面测试")
print("="*80)

# ── User 1: 王爱林 65岁退休女教师 阳虚体质 ──
print("\n👤 王爱林 — 65岁退休女教师，阳虚体质")
auth("13800000001", "Test1234", "王爱林")

r = post("/domestic/constitution/assess", {"answers": {"q1": "often_cold", "q2": "pale", "q3": "normal", "q4": "good", "q5": "sometimes_tired"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "王爱林-阳虚")

r = get("/domestic/solar-terms")
log("节气", "GET", "/domestic/solar-terms", r, "王爱林")

r = get("/domestic/solar-terms/current")
log("当前节气", "GET", "/domestic/solar-terms/current", r, "王爱林")

r = post("/domestic/food-therapy", {"season": "winter", "constitution_type": "yangxu"})
log("食疗", "POST", "/domestic/food-therapy(winter/阳虚)", r, "王爱林")

r = get("/content/featured", limit=5)
log("推荐内容", "GET", "/content/featured", r, "王爱林")

r = get("/content/search", q="冬季养生", content_type="solar_term", page_size=3)
log("内容搜索", "GET", "/content/search(冬季养生)", r, "王爱林")

r = get("/content/search", q="养生", content_type="acupoint")
log("穴位搜索", "GET", "/content/search(acupoint)", r, "王爱林")

r = post("/diary", {"title": "冬至养生日记", "content": "今天泡了脚，喝了姜汤，感觉暖和一些了。晚上10点睡觉，比平时早了一小时。", "mood": "calm"})
log("日记", "POST", "/diary", r, "王爱林")

r = get("/wellness/daily-plans")
log("每日计划", "GET", "/wellness/daily-plans", r, "王爱林")

r = post("/wellness/habit-logs", {"habit_type": "sleep", "value": 5.5})
log("习惯记录", "POST", "/wellness/habit-logs(睡眠5.5h)", r, "王爱林")

r = post("/users/me/checkin", {})
log("签到", "POST", "/users/me/checkin", r, "王爱林")

r = get("/users/me/badges")
log("徽章", "GET", "/users/me/badges", r, "王爱林")

print("  🤖 AI教练 (DeepSeek v4)...")
r = post("/wellness/coach/chat", {"message": "我今年65岁，冬天特别怕冷，手脚冰凉，睡眠也不好，经常凌晨3点就醒了。中医说我阳虚，请问我日常应该怎么调理？饮食上需要注意什么？"})
log("AI教练", "POST", "/wellness/coach/chat", r, "王爱林")

# ── User 2: 李明 28岁程序员 阴虚体质 ──
print("\n👤 李明 — 28岁程序员，阴虚体质")
auth("13800000002", "Test1234", "李明")

r = post("/domestic/constitution/assess", {"answers": {"q1": "sometimes_hot", "q2": "red", "q3": "thirsty", "q4": "poor", "q5": "often_tired"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "李明-阴虚")

r = post("/domestic/food-therapy", {"season": "summer", "constitution_type": "yinxu"})
log("食疗", "POST", "/domestic/food-therapy(summer/阴虚)", r, "李明")

r = get("/content/search", q="熬夜", content_type="solar_term", page_size=3)
log("内容搜索", "GET", "/content/search(熬夜)", r, "李明")

r = post("/diary", {"title": "加班日记录", "content": "又加班到11点，眼睛很干，喝了菊花茶。明天要早睡！", "mood": "tired"})
log("日记", "POST", "/diary", r, "李明")

r = get("/wellness/daily-plans")
log("每日计划", "GET", "/wellness/daily-plans", r, "李明")

r = post("/wellness/habit-logs", {"habit_type": "water", "value": 1.5})
log("习惯记录", "POST", "/wellness/habit-logs(饮水1.5L)", r, "李明")

print("  🤖 AI教练 (DeepSeek v4)...")
r = post("/wellness/coach/chat", {"message": "我每天加班到晚上11点，经常熬夜写代码，最近口干舌燥，容易上火，眼睛干涩，大便也偏干。中午经常吃外卖，几乎不运动。请给我一些简单易行的调理建议，最好不用花太多时间。"})
log("AI教练", "POST", "/wellness/coach/chat", r, "李明")

# ── User 3: 张美 32岁二胎孕妈 气虚体质 ──
print("\n👤 张美 — 32岁二胎孕妈，气虚体质")
auth("13800000003", "Test1234", "张美")

r = post("/domestic/constitution/assess", {"answers": {"q1": "sometimes_cold", "q2": "pale", "q3": "normal", "q4": "sometimes_tired", "q5": "short_breath"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "张美-气虚")

r = post("/domestic/food-therapy", {"season": "spring", "constitution_type": "qixu"})
log("食疗", "POST", "/domestic/food-therapy(spring/气虚)", r, "张美")

r = post("/diary", {"title": "孕期调理笔记", "content": "今天去产检，一切正常。医生说要多吃红枣和山药。晚上煮了红枣枸杞粥。", "mood": "happy"})
log("日记", "POST", "/diary", r, "张美")

print("  🤖 AI教练 (DeepSeek v4)...")
r = post("/wellness/coach/chat", {"message": "我怀孕6个月了，是二胎。最近总觉得气短乏力，爬两层楼就喘，脸色也不好看。想吃点补气的东西，又怕影响胎儿。请问我可以吃什么来补气养血？有哪些食物或药材需要避免？"})
log("AI教练", "POST", "/wellness/coach/chat", r, "张美")

# ── User 4: 陈小雨 22岁大学生 痰湿体质 ──
print("\n👤 陈小雨 — 22岁大学生，痰湿体质")
auth("13800000004", "Test1234", "陈小雨")

r = post("/domestic/constitution/assess", {"answers": {"q1": "normal", "q2": "oily", "q3": "sweet", "q4": "sometimes_tired", "q5": "often_tired"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "陈小雨-痰湿")

r = post("/domestic/food-therapy", {"season": "summer", "constitution_type": "tanshi"})
log("食疗", "POST", "/domestic/food-therapy(summer/痰湿)", r, "陈小雨")

r = post("/diary", {"title": "戒糖第一天", "content": "今天忍住了没喝奶茶！中午吃了薏米红豆粥，感觉还不错。加油！", "mood": "energetic"})
log("日记", "POST", "/diary", r, "陈小雨")

# ── User 5: 赵大伟 45岁销售 湿热体质 ──
print("\n👤 赵大伟 — 45岁销售经理，湿热体质")
auth("13800000005", "Test1234", "赵大伟")

r = post("/domestic/constitution/assess", {"answers": {"q1": "often_hot", "q2": "red_oily", "q3": "bitter", "q4": "poor", "q5": "sometimes_tired"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "赵大伟-湿热")

r = post("/domestic/food-therapy", {"season": "autumn", "constitution_type": "shire"})
log("食疗", "POST", "/domestic/food-therapy(autumn/湿热)", r, "赵大伟")

# ── User 6: 刘慧 55岁更年期 气郁体质 ──
print("\n👤 刘慧 — 55岁更年期女性，气郁体质")
auth("13800000006", "Test1234", "刘慧")

r = post("/domestic/constitution/assess", {"answers": {"q1": "normal", "q2": "normal", "q3": "normal", "q4": "sometimes_tired", "q5": "anxious"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "刘慧-气郁")

r = post("/domestic/food-therapy", {"season": "spring", "constitution_type": "qiyu"})
log("食疗", "POST", "/domestic/food-therapy(spring/气郁)", r, "刘慧")

# ── User 7: 孙浩然 35岁健身教练 平和体质 ──
print("\n👤 孙浩然 — 35岁健身教练，平和体质")
auth("13800000007", "Test1234", "孙浩然")

r = post("/domestic/constitution/assess", {"answers": {"q1": "normal", "q2": "normal", "q3": "normal", "q4": "good", "q5": "energetic"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "孙浩然-平和")

r = post("/domestic/food-therapy", {"season": "summer", "constitution_type": "pinghe"})
log("食疗", "POST", "/domestic/food-therapy(summer/平和)", r, "孙浩然")

# ── User 8: 黄丽丽 40岁白领 血瘀体质 ──
print("\n👤 黄丽丽 — 40岁白领，血瘀体质")
auth("13800000008", "Test1234", "黄丽丽")

r = post("/domestic/constitution/assess", {"answers": {"q1": "sometimes_cold", "q2": "dark_spots", "q3": "normal", "q4": "poor", "q5": "sometimes_tired"}})
log("体质评估", "POST", "/domestic/constitution/assess", r, "黄丽丽-血瘀")

r = post("/domestic/food-therapy", {"season": "winter", "constitution_type": "xueyu"})
log("食疗", "POST", "/domestic/food-therapy(winter/血瘀)", r, "黄丽丽")

# ── Constitution types list ──
print("\n📋 体质类型列表")
r = get("/domestic/constitution/types")
log("体质类型", "GET", "/domestic/constitution/types", r)

# ── Content types ──
print("\n📋 内容类型")
r = get("/content/types")
log("内容类型", "GET", "/content/types", r)

# ── Family management ──
print("\n👨‍👩‍👧‍👦 家庭管理")
s.headers.update({"Authorization": f"Bearer {auth('13800000001', 'Test1234', '王爱林')}"})
r = post("/domestic/family", {"name": "王爱林的家庭"})
log("家庭", "POST", "/domestic/family", r, "王爱林")
r = get("/domestic/family")
log("家庭", "GET", "/domestic/family", r, "王爱林")

# Save results
with open("/Users/feifei00/workspace/shunshi/backend/test_results_domestic.json", "w") as f:
    json.dump(results, f, ensure_ascii=False, indent=2, default=str)

print(f"\n✅ 国内版测试完成: {len(results)} 个测试用例")
print("结果已保存到 test_results_domestic.json")
