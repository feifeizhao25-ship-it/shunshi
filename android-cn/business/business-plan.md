# 顺时 ShunShi 商业计划书专用提示词

你是世界级产品策略师、商业分析师、投资人沟通专家。

你的任务是为「顺时 ShunShi」生成完整的商业化方案、投资人叙事和财务模型。

---

## 一、执行摘要

### 1.1 一句话定位

**顺时 ShunShi** - 中国版 "Calm + Headspace"，面向10亿追求健康生活的中国用户，打造AI驱动的**生活节律陪伴平台**。

### 1.2 核心价值主张

```
┌─────────────────────────────────────────────────────────────────┐
│                    顺时的独特价值                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. AI 驱动的个性化                                              │
│     • 不是工具，是"懂你"的 AI 朋友                                │
│     • 越用越懂，长期记忆，陪伴一生                                 │
│                                                                 │
│  2. 东方养生文化                                                 │
│     • 节气、养生、食疗、穴位                                       │
│     • 文化认同，差异化定位                                         │
│                                                                 │
│  3. 家庭网络效应                                                 │
│     • 子女为父母购买                                             │
│     • 一个用户带来 4-6 个家庭成员                                 │
│                                                                 │
│  4. 数据护城河                                                   │
│     • 长期生活节律数据                                            │
│     • 随时间增值，越老越值钱                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、市场分析

### 2.1 市场机会

```python
MARKET_SIZE = {
    "tam": {  # Total Addressable Market
        "name": "全球健康市场",
        "size": 10000,  # 10万亿美元
        "source": "Grand View Research 2023"
    },
    
    "sam": {  # Serviceable Addressable Market
        "name": "中国大健康市场",
        "size": 16,  # 16万亿元人民币
        "year": 2025,
        "cagr": 10  # 年增长率
    },
    
    "som": {  # Serviceable Obtainable Market
        "name": "AI健康应用市场",
        "size": 500,  # 500亿元人民币
        "year": 2027
    }
}

# 细分市场
SEGMENTS = {
    "meditation": {
        "name": "冥想/心理健康",
        "global_leaders": ["Calm", "Headspace"],
        "china_market": "50亿元",
        "shunshi_opportunity": "情绪陪伴+养生"
    },
    
    "health_tracking": {
        "name": "健康追踪",
        "global_leaders": ["Apple Health", "Fitbit"],
        "china_market": "100亿元",
        "shunshi_opportunity": "生活节律+习惯"
    },
    
    "elderly_care": {
        "name": "养老陪伴",
        "china_market": "200亿元",
        "shunshi_opportunity": "AI陪伴+家庭连接"
    }
}
```

### 2.2 竞争格局

```
竞争格局分析

                    高端付费
                       ▲
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        │    Calm      │   顺时       │
        │  Headspace  │  (我们)      │
        │              │              │
        ├──────────────┼──────────────┤
        │              │              │
        │   Keep      │  小睡眠      │
        │   蜗牛      │  潮汐        │
        │              │              │
        └──────────────┼──────────────┘
                       │
                    免费/低价

差异化定位：
- Calm/Headspace: 西方冥想
- Keep: 运动健身
- 顺时: 东方养生 + AI陪伴 + 家庭关怀
```

### 2.3 用户画像

```python
USER_PERSONAS = {
    "exploring": {
        "name": "小美",
        "age": "22岁",
        "occupation": "互联网运营",
        "pain_points": ["失眠", "焦虑", "作息不规律"],
        "willingness_to_pay": 28,  # 月付费意愿
        "acquisition_channel": ["小红书", "B站"]
    },
    
    "stressed": {
        "name": "大明",
        "age": "32岁",
        "occupation": "产品经理",
        "pain_points": ["工作压力大", "睡眠差", "没时间健身"],
        "willingness_to_pay": 68,
        "acquisition_channel": ["脉脉", "朋友圈"]
    },
    
    "healthy": {
        "name": "张阿姨",
        "age": "50岁",
        "occupation": "退休",
        "pain_points": ["养生知识缺乏", "子女不在身边"],
        "willingness_to_pay": 68,
        "acquisition_channel": ["子女推荐", "微信"]
    },
    
    "companion": {
        "name": "王爷爷",
        "age": "70岁",
        "occupation": "退休",
        "pain_points": ["孤独", "需要陪伴", "操作困难"],
        "willingness_to_pay": 128,  # 子女付费
        "acquisition_channel": ["子女购买", "社区"]
    }
}
```

---

## 三、商业模式

### 3.1 收入模型

```python
REVENUE_MODEL = {
    "subscriptions": {
        "name": "订阅收入",
        "tiers": [
            {
                "name": "免费版",
                "price": 0,
                "features": ["基础对话", "节气查询", "3个习惯"],
                "conversion_rate": 1.0
            },
            {
                "name": "养心版",
                "price": 28,  # 月
                "features": ["深记忆30天", "家庭1人", "AI优先响应"],
                "conversion_rate": 0.05  # 5%
            },
            {
                "name": "颐养版",
                "price": 68,
                "features": ["完整记忆", "家庭3人", "全部Skills"],
                "conversion_rate": 0.02
            },
            {
                "name": "家和版",
                "price": 128,
                "features": ["无限记忆", "家庭无限", "专属客服"],
                "conversion_rate": 0.01
            }
        ],
        "arpu": 8.5  # 综合 ARPU
    },
    
    "gifts": {
        "name": "礼物订阅",
        "scenarios": [
            "父母生日", "母亲节", "父亲节", "春节"
        ],
        "average_price": 268,  # 年费
        "take_rate": 0.10  # 10% 礼物市场
    },
    
    "enterprise": {
        "name": "企业服务",
        "pricing": "20元/人/月",
        "features": ["员工健康报告", "压力监测", "团队活动"]
    },
    
    "future": {
        "name": "未来收入",
        "hardware": "智能设备分成",
        "content": "养生课程付费",
        "services": "专家咨询"
    }
}
```

### 3.2 Unit Economics

```python
UNIT_ECONOMICS = {
    "cac": {  # Customer Acquisition Cost
        "organic": 5,    # 自然获客
        "paid": 50,      # 付费获客
        "blended": 15    # 综合 CAC
    },
    
    "ltv": {  # Lifetime Value
        "free_user": 0,
        "paid_user_1y": 150,    # 1年付费用户 LTV
        "paid_user_3y": 400,    # 3年付费用户 LTV
        "family_user_3y": 800   # 家庭用户 LTV
    },
    
    "ltv_cac_ratio": {
        "paid": 150 / 50,  # 3x
        "family": 800 / 50  # 16x
    },
    
    "margin": {
        "gross": 0.70,   # 70% 毛利
        "net": 0.20      # 20% 净利（规模化后）
    },
    
    "payback_period": {
        "individual": "12个月",
        "family": "6个月"
    }
}
```

---

## 四、增长策略

### 4.1 增长飞轮

```
                     ┌──────────────┐
                     │   产品价值    │
                     │  (用户留存)   │
                     └──────┬───────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   内容分享   │   │   社交裂变   │   │   口碑传播   │
│  节气卡片    │   │ 子女为父母   │   │  真诚服务    │
│  食疗推荐    │   │  家庭邀请    │   │  用户推荐    │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          ▼
                 ┌──────────────┐
                 │   用户增长   │
                 │  (口碑+投放) │
                 └──────────────┘
```

### 4.2 增长策略

```python
GROWTH_STRATEGY = {
    "phase_1_mvp": {
        "duration": "0-6个月",
        "goal": "产品验证",
        "kpis": ["DAU 1万", "次留 40%", "7留 20%"],
        "channels": ["自然增长", "KOL试用", "社群"]
    },
    
    "phase_2_product_market_fit": {
        "duration": "6-12个月",
        "goal": "找到 PMF",
        "kpis": ["DAU 50万", "付费率 5%", "NPS 50+"],
        "channels": ["口碑传播", "内容营销", "节气营销"]
    },
    
    "phase_3_scale": {
        "duration": "12-24个月",
        "goal": "规模化增长",
        "kpis": ["DAU 500万", "付费用户 50万", "ARR 1亿"],
        "channels": ["投放增长", "家庭裂变", "节日营销"]
    },
    
    "phase_4_expansion": {
        "duration": "24-36个月",
        "goal": "多维度扩展",
        "kpis": ["DAU 2000万", "付费用户 200万", "ARR 5亿"],
        "channels": ["硬件接入", "企业服务", "海外版本"]
    }
}
```

---

## 五、财务预测

### 5.1 收入预测

```python
FINANCIAL_PROJECTION = {
    "year_1": {
        "users": {
            "total": 1_000_000,
            "free": 950_000,
            "paid_yangxin": 40_000,
            "paid_yiyang": 8_000,
            "paid_jiahe": 2_000
        },
        "revenue": {
            "subscriptions": 2_400_000,  # 240万
            "gifts": 200_000,
            "total": 2_600_000  # 260万
        },
        "expenses": {
            "rnd": 3_000_000,
            "marketing": 2_000_000,
            "operations": 1_000_000,
            "total": 6_000_000
        },
        "profit": -3_400_000  # 亏损340万
    },
    
    "year_3": {
        "users": {
            "total": 5_000_000,
            "paid_yangxin": 200_000,
            "paid_yiyang": 50_000,
            "paid_jiahe": 10_000
        },
        "revenue": {
            "subscriptions": 18_000_000,
            "gifts": 2_000_000,
            "enterprise": 1_000_000,
            "total": 21_000_000  # 2100万
        },
        "profit": 5_000_000  # 盈利500万
    },
    
    "year_5": {
        "users": {
            "total": 20_000_000,
            "paid": 2_000_000
        },
        "revenue": {
            "subscriptions": 150_000_000,
            "gifts": 20_000_000,
            "enterprise": 30_000_000,
            "total": 200_000_000  # 2亿
        },
        "profit": 60_000_000  # 盈利6000万
    }
}
```

### 5.2 融资规划

```python
FUNDING_PLAN = {
    "seed": {
        "amount": "300万美元",
        "timeline": "MVP阶段",
        "use_of_funds": [
            "产品开发 60%",
            "市场验证 30%",
            "团队 10%"
        ],
        "milestone": "MVP上线"
    },
    
    "series_a": {
        "amount": "1500万美元",
        "timeline": "PMF验证后",
        "use_of_funds": [
            "增长投放 40%",
            "产品迭代 30%",
            "团队扩张 20%",
            "运营 10%"
        ],
        "milestone": "付费用户10万"
    },
    
    "series_b": {
        "amount": "5000万美元",
        "timeline": "规模化阶段",
        "use_of_funds": [
            "市场扩张 50%",
            "产品矩阵 25%",
            "团队 15%",
            "战略投资 10%"
        ],
        "milestone": "付费用户100万"
    },
    
    "series_c": {
        "amount": "1-2亿美元",
        "timeline": "市场领导",
        "use_of_funds": [
            "国际化 30%",
            "生态建设 30%",
            "并购 20%",
            "团队 20%"
        ],
        "milestone": "付费用户500万"
    }
}
```

---

## 六、护城河分析

### 6.1 五大护城河

```python
MOAT_ANALYSIS = {
    "data_moat": {
        "description": "数据护城河",
        "strength": "强",
        "elements": [
            "用户行为数据",
            "健康趋势数据",
            "家庭关系数据",
            "AI训练数据"
        ],
        "competitor_difficulty": "需要5-10年积累",
        "valuation_impact": "+30% 估值倍数"
    },
    
    "relationship_moat": {
        "description": "关系护城河",
        "strength": "强",
        "elements": [
            "用户习惯依赖",
            "家庭网络效应",
            "子女-父母纽带"
        ],
        "competitor_difficulty": "迁移成本高",
        "valuation_impact": "+20% LTV"
    },
    
    "ai_moat": {
        "description": "AI护城河",
        "strength": "中强",
        "elements": [
            "Prompt版本管理",
            "Skills系统",
            "AI Router",
            "人格一致性"
        ],
        "competitor_difficulty": "需要大量调优",
        "valuation_impact": "+20% 估值倍数"
    },
    
    "brand_moat": {
        "description": "品牌护城河",
        "strength": "中",
        "elements": [
            "东方养生文化",
            "信任",
            "情感连接"
        ],
        "competitor_difficulty": "品牌需要时间",
        "valuation_impact": "+10% CAC效率"
    },
    
    "ecosystem_moat": {
        "description": "生态护城河",
        "strength": "中",
        "elements": [
            "硬件接入",
            "企业服务",
            "家庭网络"
        ],
        "competitor_difficulty": "网络效应",
        "valuation_impact": "+30% 天花板"
    }
}
```

---

## 七、团队

### 7.1 核心团队

```python
TEAM = {
    "ceo": {
        "name": "CEO",
        "background": "连续创业者，前大厂产品总监",
        "strengths": ["产品洞察", "团队管理", "融资能力"]
    },
    
    "cto": {
        "name": "CTO",
        "background": "前大厂AI负责人",
        "strengths": ["AI技术", "架构能力", "工程管理"]
    },
    
    "cpo": {
        "name": "CPO",
        "background": "前 Calm/Headspace 核心产品",
        "strengths": ["健康产品经验", "国际化视野"]
    },
    
    "cmo": {
        "name": "CMO",
        "background": "前字节/快手增长负责人",
        "strengths": ["增长黑客", "投放策略"]
    }
}

# 早期团队规模
TEAM_SIZE = {
    "seed": 10,
    "series_a": 30,
    "series_b": 80,
    "series_c": 200
}
```

---

## 八、里程碑

### 8.1 产品路线图

```
里程碑时间线

2026 Q2 ─── MVP 上线
            ├── 基础对话
            ├── 节气系统
            ├── 基础习惯
            └── 目标: 10万用户
                     │
2026 Q4 ─── 家庭系统上线
            ├── 家庭邀请
            ├── 关怀消息
            └── 目标: 50万用户
                     │
2027 Q2 ─── 订阅系统上线
            ├── 4个订阅级别
            ├── 礼物订阅
            └── 目标: 100万用户, 付费率5%
                     │
2027 Q4 ─── 硬件接入
            ├── Apple Watch
            ├── 小米手环
            └── 目标: 300万用户
                     │
2028 Q2 ─── 企业版上线
            ├── 员工关怀
            └── 目标: 500万用户
                     │
2028 Q4 ─── 养老版上线
            ├── 老年模式
            ├── 语音优先
            └── 目标: 800万用户
                     │
2029- ────  全球化
            ├── 东南亚
            ├── 日韩
            └── 目标: 1亿用户
```

---

## 九、投资亮点

### 9.1 一句话总结

**顺时** - 中国唯一AI驱动的生活节律陪伴平台，差异化定位东方养生文化，家庭网络效应带来低成本高LTV，万亿健康市场中极具潜力的下一个超级App。

### 9.2 投资亮点

```python
INVESTMENT_HIGHLIGHTS = [
    {
        "highlight": "巨大市场机会",
        "description": "中国大健康市场16万亿，AI健康应用500亿蓝海"
    },
    {
        "highlight": "差异化定位",
        "description": "东方养生+AI陪伴+家庭关怀，无直接竞争对手"
    },
    {
        "highlight": "强大网络效应",
        "description": "1个用户带来4-6个家庭成员，LTV/CAC > 10x"
    },
    {
        "highlight": "数据护城河",
        "description": "长期生活节律数据，越老越值钱"
    },
    {
        "highlight": "高效增长模型",
        "description": "产品驱动增长，口碑占比60%，CAC极低"
    },
    {
        "highlight": "可扩展收入",
        "description": "个人订阅+家庭礼物+企业服务+硬件生态"
    },
    {
        "highlight": "经验团队",
        "description": "大厂背景+创业经验+健康赛道专家"
    }
]
```

---

## 十、风险与应对

### 10.1 主要风险

```python
RISKS = {
    "competition": {
        "risk": "大厂入场竞争",
        "likelihood": "高",
        "mitigation": [
            "快速建立数据护城河",
            "深耕家庭场景",
            "差异化文化定位"
        ]
    },
    
    "regulation": {
        "risk": "医疗健康监管",
        "likelihood": "中",
        "mitigation": [
            "明确不做医疗",
            "合规审核机制",
            "与监管保持沟通"
        ]
    },
    
    "ai_safety": {
        "risk": "AI安全问题",
        "likelihood": "中",
        "mitigation": [
            "多层安全审核",
            "情绪安全系统",
            "人工复核机制"
        ]
    },
    
    "retention": {
        "risk": "用户留存低",
        "likelihood": "中",
        "mitigation": [
            "产品价值优先",
            "家庭绑定",
            "持续功能迭代"
        ]
    }
}
```

---

## 十一、附录

### 11.1 关键指标

```python
KEY_METRICS = {
    "product": [
        "DAU / MAU",
        "用户留存 (1/7/30日)",
        "日均使用时长",
        "功能使用率"
    ],
    
    "business": [
        "付费转化率",
        "ARPU",
        "LTV",
        "CAC",
        "LTV/CAC"
    ],
    
    "growth": [
        "新增用户",
        "自然增长占比",
        "NPS",
        "用户终身价值"
    ],
    
    "financial": [
        "ARR",
        "毛利率",
        "净利率",
        "用户获取成本"
    ]
}
```

### 11.2 联系信息

```
联系方式

CEO: [CEO名字]
Email: ceo@shunshi.com
Phone: [手机号]

更多信息请访问: www.shunshi.com
```

---

*本商业计划书为内部文档，仅供投资人沟通使用*
*版本: 1.0*
*日期: 2026年3月*
