"""顺3 手算复算：小雪食材在过滤前后各是什么。

运行：python backend/scripts/recheck_solar_audience.py
不调用模型，不读密钥。依据是《中医体质分类与判定》里阴虚、湿热宜清润、少温燥，
以及孕期对桂圆、羊肉的常见慎用提示。这里只做生活提示过滤，不是诊断。
"""
from app.services.solar_audience import filter_solar_term

# 与 backend/app/router/solar_terms.py 里小雪条目一致的旧结果。
term = {
    "name": "小雪",
    "description": "小雪时节，雪开始落下，但不大。养生重在温肾助阳。",
    "suggestions": ["温肾助阳", "适当进补", "注意保暖", "预防感冒"],
    "foods": ["羊肉", "核桃", "黑豆", "红枣", "桂圆"],
}
old_foods = list(term["foods"])
old_lead = term["suggestions"][0]
cases = [
    ("无人群", None, None),
    ("阴虚", "阴虚", None),
    ("湿热质", "湿热质", None),
    ("孕期", None, "孕期"),
]


def main() -> None:
    print("输入节气: 小雪")
    print(f"旧主建议: {old_lead}")
    print(f"旧食材: {old_foods}")
    print("正确值: 阴虚或湿热的主建议不含「温肾助阳」，食材不含羊肉、桂圆；孕期出现慎用提示。")
    for label, cons, stage in cases:
        new = filter_solar_term(term, constitution=cons, life_stage=stage)
        print(f"\n[{label}]")
        print(f"  新主建议: {new['primary_suggestion']}")
        print(f"  新食材: {new['foods']}")
        print(f"  提示: {new['audience_notes']}")


if __name__ == "__main__":
    main()
