"""顺2 复算：同一天早晨五类用户的首页标题。

运行：cd backend && PYTHONPATH=. python scripts/recheck_home_personalization.py
不调用模型。依据是首页打分：体质专属卡、地区气候、年龄段、会员档、心情记录会各自占一张卡。
关掉个性化后只剩调用方传入的通用节气卡。
"""
from datetime import datetime
from zoneinfo import ZoneInfo

from app.services import personal_home as ph

WHEN = datetime(2026, 11, 24, 8, tzinfo=ZoneInfo("Asia/Shanghai"))
PERSONAS = {
    "气郁·北京": ph.Profile(lang="zh", season="winter", goals=frozenset({"mood"}), constitution="气郁", zone="华北"),
    "痰湿·会员": ph.Profile(lang="zh", season="winter", goals=frozenset({"food"}), constitution="痰湿", zone="华北", membership_tier="yiyang"),
    "阳虚·长辈·上海": ph.Profile(lang="zh", season="winter", goals=frozenset({"food"}), constitution="阳虚", zone="华东华中", life_stage="长辈", age_group="senior"),
    "气虚·心情偏低": ph.Profile(lang="zh", season="winter", goals=frozenset({"sleep"}), constitution="气虚", zone="华东华中", recent_mood="low"),
    "阴虚·华南": ph.Profile(lang="zh", season="winter", goals=frozenset({"food"}), constitution="阴虚", zone="华南"),
}


def main() -> None:
    print("输入日期: 2026-11-24 08:00 北京时间，季节=冬")
    print("旧结果: 五人标题几乎相同，只在理由后加一句体质。")
    boards = {}
    for name, profile in PERSONAS.items():
        board = ph.compose(profile, ph.Activity(), name, WHEN, "weekday")
        boards[name] = board
        print(f"\n[{name}] 问候: {board['greeting']}")
        for card in board["cards"]:
            print(f"  - {card['title']} ｜ 为什么推荐给你：{card['reason']}")
    names = list(boards)
    print("\n两两标题重合比例（交集/并集，应 ≤ 0.5）")
    for i, left in enumerate(names):
        for right in names[i + 1:]:
            a = {card["title"] for card in boards[left]["cards"]}
            b = {card["title"] for card in boards[right]["cards"]}
            print(f"  {left} vs {right}: {len(a & b) / len(a | b):.2f}")


if __name__ == "__main__":
    main()
