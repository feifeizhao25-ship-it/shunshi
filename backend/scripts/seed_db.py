#!/usr/bin/env python3
"""
顺时 ShunShi — 数据库 Seed 脚本
初始化必要的基础数据：用户、会员计划、节气、体质题库等。
用法: python scripts/seed_db.py
"""
import os
import sys
import json
import uuid
from datetime import datetime, timedelta, date

# 确保项目根目录
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine, Session, init_db
from app.models.base import Base


def seed_all():
    """执行所有 seed"""
    init_db()
    db = Session()
    try:
        _seed_users(db)
        _seed_membership_plans(db)
        _seed_constitution_questions(db)
        _seed_solar_terms(db)
        _seed_subscription_products(db)
        _seed_notification_settings(db)
        _seed_gamification(db)
        _seed_sample_journal(db)
        db.commit()
        print("[SEED] 全部 seed 数据写入完成")
    except Exception as e:
        db.rollback()
        print(f"[SEED] 错误: {e}")
        raise
    finally:
        db.close()


# 测试用户 UUID（字符串形式用于 user_id 关联）
TEST_USER_1_UUID = uuid.uuid4()
TEST_USER_1_STR = str(TEST_USER_1_UUID)
TEST_USER_2_UUID = uuid.uuid4()
TEST_USER_2_STR = str(TEST_USER_2_UUID)


def _seed_users(db):
    """创建测试用户"""
    from app.models.user import User, UserAuth
    if db.query(User).filter(User.id == TEST_USER_1_UUID).first():
        print("[SEED] 用户已存在，跳过")
        return

    # 测试用户 1
    user = User(id=TEST_USER_1_UUID, nickname="测试用户", gender="female",
                birth_date=date(1995, 5, 15), avatar_url="")
    db.add(user)
    auth = UserAuth(id=uuid.uuid4(), user_id=TEST_USER_1_UUID, auth_type="phone",
                    auth_identifier="13800138000")
    db.add(auth)

    # 测试用户 2
    user2 = User(id=TEST_USER_2_UUID, nickname="张三", gender="male",
                 birth_date=date(1990, 3, 20), avatar_url="")
    db.add(user2)
    auth2 = UserAuth(id=uuid.uuid4(), user_id=TEST_USER_2_UUID, auth_type="wechat",
                     auth_identifier="wx_test_12345")
    db.add(auth2)
    db.flush()
    print("[SEED] 2 个测试用户创建完成")


def _seed_membership_plans(db):
    """创建会员计划"""
    from app.models.membership import MembershipPlan
    if db.query(MembershipPlan).first():
        print("[SEED] 会员计划已存在，跳过")
        return

    plans = [
        MembershipPlan(code="free", name="免费版", price_cny=0,
                       features=[{"feature": "basic_chat", "included": True},
                                 {"feature": "basic_report", "included": True}],
                       description="基础功能"),
        MembershipPlan(code="monthly", name="月度会员", price_cny=29.9,
                       features=[{"feature": "advanced_chat", "included": True},
                                 {"feature": "full_report", "included": True},
                                 {"feature": "exclusive_content", "included": True},
                                 {"feature": "followup", "included": True}],
                       duration_days=30, description="解锁全部AI功能和深度报告"),
        MembershipPlan(code="quarterly", name="季度会员", price_cny=74.7,
                       features=[{"feature": "advanced_chat", "included": True},
                                 {"feature": "full_report", "included": True},
                                 {"feature": "exclusive_content", "included": True},
                                 {"feature": "followup", "included": True},
                                 {"feature": "family", "included": True}],
                       duration_days=90, description="季度优惠，含家庭功能"),
        MembershipPlan(code="yearly", name="年度会员", price_cny=238.8,
                       features=[{"feature": "advanced_chat", "included": True},
                                 {"feature": "full_report", "included": True},
                                 {"feature": "exclusive_content", "included": True},
                                 {"feature": "followup", "included": True},
                                 {"feature": "family", "included": True},
                                 {"feature": "priority_support", "included": True}],
                       duration_days=365, description="年度最优价，全部功能"),
    ]
    for p in plans:
        db.add(p)
    db.flush()
    print("[SEED] 4 个会员计划创建完成")


def _seed_constitution_questions(db):
    """创建中医体质辨识题库"""
    from app.models.constitution import ConstitutionQuestion
    if db.query(ConstitutionQuestion).first():
        print("[SEED] 体质题库已存在，跳过")
        return

    questions = [
        ConstitutionQuestion(question_text="您容易感到疲倦吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=1, category="qi_deficiency"),
        ConstitutionQuestion(question_text="您容易感冒吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=2, category="qi_deficiency"),
        ConstitutionQuestion(question_text="您说话声音低弱吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=3, category="qi_deficiency"),
        ConstitutionQuestion(question_text="您容易心烦气躁吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=4, category="yang_deficiency"),
        ConstitutionQuestion(question_text="您手脚经常冰凉吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=5, category="yang_deficiency"),
        ConstitutionQuestion(question_text="您面色偏红吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=6, category="damp_heat"),
        ConstitutionQuestion(question_text="您皮肤容易出油吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=7, category="damp_heat"),
        ConstitutionQuestion(question_text="您容易失眠吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=8, category="yin_deficiency"),
        ConstitutionQuestion(question_text="您口干咽燥吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=9, category="yin_deficiency"),
        ConstitutionQuestion(question_text="您体型偏胖吗？",
                             options=json.dumps(["从不", "很少", "有时", "经常", "总是"],
                                                ensure_ascii=False),
                             sort_order=10, category="phlegm_damp"),
    ]
    for q in questions:
        db.add(q)
    db.flush()
    print("[SEED] 10 道体质题目创建完成")


def _seed_solar_terms(db):
    """创建24节气基础数据"""
    from app.models.solar_term import SolarTerm
    if db.query(SolarTerm).first():
        print("[SEED] 节气已存在，跳过")
        return

    terms = [
        ("立春", 2, 4, "spring", "万物复苏，养生以养肝为主"),
        ("雨水", 2, 19, "spring", "降雨开始，注意祛湿"),
        ("惊蛰", 3, 5, "spring", "春雷响动，养肝健脾"),
        ("春分", 3, 20, "spring", "昼夜平分，调和阴阳"),
        ("清明", 4, 4, "spring", "天气清朗，疏肝理气"),
        ("谷雨", 4, 19, "spring", "雨生百谷，健脾祛湿"),
        ("立夏", 5, 5, "summer", "夏季开始，养心安神"),
        ("小满", 5, 20, "summer", "麦粒渐满，清心降火"),
        ("芒种", 6, 5, "summer", "麦类成熟，清热解暑"),
        ("夏至", 6, 21, "summer", "日最长，养心护阳"),
        ("小暑", 7, 7, "summer", "天气转热，防暑降温"),
        ("大暑", 7, 22, "summer", "一年最热，清热补气"),
        ("立秋", 8, 7, "autumn", "秋季开始，养肺润燥"),
        ("处暑", 8, 22, "autumn", "暑气渐消，滋阴润肺"),
        ("白露", 9, 7, "autumn", "露水始白，润肺养阴"),
        ("秋分", 9, 22, "autumn", "昼夜平分，调和阴阳"),
        ("寒露", 10, 8, "autumn", "露水渐寒，温补养胃"),
        ("霜降", 10, 23, "autumn", "霜降开始，补肾固精"),
        ("立冬", 11, 7, "winter", "冬季开始，补肾藏精"),
        ("小雪", 11, 22, "winter", "开始降雪，温补阳气"),
        ("大雪", 12, 7, "winter", "雪量增大，补肾壮阳"),
        ("冬至", 12, 21, "winter", "日最短，进补佳期"),
        ("小寒", 1, 5, "winter", "天气转冷，温补驱寒"),
        ("大寒", 1, 20, "winter", "一年最冷，大补元气"),
    ]
    for name, month, day, season, desc in terms:
        db.add(SolarTerm(
            name=name, month=month, day=day,
            season=season, description=desc
        ))
    db.flush()
    print("[SEED] 24 节气创建完成")


def _seed_subscription_products(db):
    """创建订阅产品（支付系统用）"""
    from app.models.subscription import SubscriptionProduct
    if db.query(SubscriptionProduct).first():
        print("[SEED] 订阅产品已存在，跳过")
        return

    products = [
        SubscriptionProduct(product_id="shunshi_yangxin_monthly",
                            name="养心月度会员", tier="yangxin",
                            price=29.90, currency="CNY", duration_days=30),
        SubscriptionProduct(product_id="shunshi_yiyang_quarterly",
                            name="颐养季度会员", tier="yiyang",
                            price=74.70, currency="CNY", duration_days=90),
        SubscriptionProduct(product_id="shunshi_jiahe_yearly",
                            name="嘉和年度会员", tier="jiahe",
                            price=238.80, currency="CNY", duration_days=365),
    ]
    for p in products:
        db.add(p)
    db.flush()
    print("[SEED] 3 个订阅产品创建完成")


def _seed_notification_settings(db):
    """为测试用户创建默认通知设置"""
    # Notification settings 目前是硬编码默认值，无需 seed
    print("[SEED] 通知设置使用默认值，无需 seed")


def _seed_gamification(db):
    """创建成就徽章定义和测试用户积分"""
    from app.models.gamification import UserPoints, UserBadge

    if db.query(UserPoints).filter(UserPoints.user_id == TEST_USER_1_STR).first():
        print("[SEED] 积分数据已存在，跳过")
        return

    # 测试用户初始积分
    db.add(UserPoints(user_id=TEST_USER_1_STR, total_points=150, level=2))
    db.flush()
    print("[SEED] 积分数据创建完成")


def _seed_sample_journal(db):
    """创建示例日记"""
    from app.models.journal import JournalEntry as JournalEntryModel
    if db.query(JournalEntryModel).first():
        print("[SEED] 日记已存在，跳过")
        return

    db.add(JournalEntryModel(
        user_id=TEST_USER_1_STR,
        date=(datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d"),
        content="今天天气不错，去公园散步了一小时。按照建议做了八段锦，感觉精神好多了。",
        mood="happy", tags=json.dumps(["运动", "八段锦"], ensure_ascii=False),
    ))
    db.add(JournalEntryModel(
        user_id=TEST_USER_1_STR,
        date=datetime.now().strftime("%Y-%m-%d"),
        content="最近工作压力大，晚上睡不好。明天尝试早睡，配合冥想。",
        mood="anxious", tags=json.dumps(["睡眠", "压力"], ensure_ascii=False),
    ))
    db.flush()
    print("[SEED] 2 条示例日记创建完成")


if __name__ == "__main__":
    print("=" * 50)
    print("顺时 ShunShi — 数据库 Seed 脚本")
    print("=" * 50)
    seed_all()
