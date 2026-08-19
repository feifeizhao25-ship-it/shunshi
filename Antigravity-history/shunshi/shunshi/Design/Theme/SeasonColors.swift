import SwiftUI

// MARK: - 节气色彩管理
struct SeasonalColors {
    // MARK: - 主色调（随节气变化）
    
    /// 春季色彩 - 嫩绿/浅绿
    static let springPrimary = Color(hex: "7CB342")
    static let springSecondary = Color(hex: "AED581")
    
    /// 夏季色彩 - 青碧/浅青
    static let summerPrimary = Color(hex: "26A69A")
    static let summerSecondary = Color(hex: "80CBC4")
    
    /// 秋季色彩 - 橙红/浅橙
    static let autumnPrimary = Color(hex: "FF8A65")
    static let autumnSecondary = Color(hex: "FFAB91")
    
    /// 冬季色彩 - 靛蓝/浅紫
    static let winterPrimary = Color(hex: "5C6BC0")
    static let winterSecondary = Color(hex: "9FA8DA")
    
    /// 强调色 - 琥珀金（按钮/重点）
    static let accentGold = Color(hex: "D4A574")
    
    // MARK: - 根据节气获取当前色彩
    
    static func primary(for solarTerm: SolarTerm) -> Color {
        switch solarTerm.season {
        case .spring:
            return springPrimary
        case .summer:
            return summerPrimary
        case .autumn:
            return autumnPrimary
        case .winter:
            return winterPrimary
        }
    }
    
    static func secondary(for solarTerm: SolarTerm) -> Color {
        switch solarTerm.season {
        case .spring:
            return springSecondary
        case .summer:
            return summerSecondary
        case .autumn:
            return autumnSecondary
        case .winter:
            return winterSecondary
        }
    }
    
    // MARK: - 当前季节（根据月份）
    
    static var currentSeasonPrimary: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return springPrimary
        case 6...8:
            return summerPrimary
        case 9...11:
            return autumnPrimary
        default:
            return winterPrimary
        }
    }
    
    static var currentSeasonSecondary: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return springSecondary
        case 6...8:
            return summerSecondary
        case 9...11:
            return autumnSecondary
        default:
            return winterSecondary
        }
    }
    
    /// 当前季节主色调 - 深色版本
    static var currentSeasonPrimaryDark: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return Color(hex: "558B2F")  // 深绿
        case 6...8:
            return Color(hex: "00897B")  // 深青
        case 9...11:
            return Color(hex: "E64A19")  // 深橙
        default:
            return Color(hex: "3949AB")  // 深靛蓝
        }
    }
}

// MARK: - UI季节枚举 (设计主题专用)
enum UISeason: String, CaseIterable {
    case spring = "春"
    case summer = "夏"
    case autumn = "秋"
    case winter = "冬"

    var primaryColor: Color {
        switch self {
        case .spring: return SeasonalColors.springPrimary
        case .summer: return SeasonalColors.summerPrimary
        case .autumn: return SeasonalColors.autumnPrimary
        case .winter: return SeasonalColors.winterPrimary
        }
    }

    var secondaryColor: Color {
        switch self {
        case .spring: return SeasonalColors.springSecondary
        case .summer: return SeasonalColors.summerSecondary
        case .autumn: return SeasonalColors.autumnSecondary
        case .winter: return SeasonalColors.winterSecondary
        }
    }
}

// MARK: - UI节气模型 (设计主题专用)
struct UISolarTerm: Identifiable {
    let id = UUID()
    let name: String
    let season: UISeason
    let month: Int
    let day: Int
    let description: String
    let threeHou: [String] // 三候

    var displayName: String {
        name
    }
}

// MARK: - 常用节气列表
extension UISolarTerm {
    static let allSolarTerms: [UISolarTerm] = [
        // 春季
        UISolarTerm(name: "立春", season: .spring, month: 2, day: 4, description: "春天开始，万物复苏", threeHou: ["东风解冻", "蛰虫始振", "鱼陟负冰"]),
        UISolarTerm(name: "雨水", season: .spring, month: 2, day: 19, description: "降雨开始，春雨绵绵", threeHou: ["獭祭鱼", "鸿雁来", "草木萌动"]),
        UISolarTerm(name: "惊蛰", season: .spring, month: 3, day: 6, description: "春雷始鸣，万物苏醒", threeHou: ["桃始华", "仓庚鸣", "鹰化为鸠"]),
        UISolarTerm(name: "春分", season: .spring, month: 3, day: 21, description: "昼夜平分，气候温和", threeHou: ["玄鸟至", "雷乃发声", "始电"]),
        UISolarTerm(name: "清明", season: .spring, month: 4, day: 5, description: "气清景明，万物皆显", threeHou: ["桐始华", "田鼠化为鴽", "虹始见"]),
        UISolarTerm(name: "谷雨", season: .spring, month: 4, day: 20, description: "雨生百谷，滋养万物", threeHou: ["萍始生", "鸣鸠拂其羽", "戴胜降于桑"]),

        // 夏季
        UISolarTerm(name: "立夏", season: .summer, month: 5, day: 6, description: "夏天开始，绿树成荫", threeHou: ["蝼蝈鸣", "蚯蚓出", "王瓜生"]),
        UISolarTerm(name: "小满", season: .summer, month: 5, day: 21, description: "麦穗饱满，夏熟作物成熟", threeHou: ["苦菜秀", "靡草死", "麦秋至"]),
        UISolarTerm(name: "芒种", season: .summer, month: 6, day: 6, description: "麦类有芒，仲夏时节", threeHou: ["螳螂生", "鵙始鸣", "反舌无声"]),
        UISolarTerm(name: "夏至", season: .summer, month: 6, day: 21, description: "白昼最长，夏日炎炎", threeHou: ["鹿角解", "蝉始鸣", "半夏生"]),
        UISolarTerm(name: "小暑", season: .summer, month: 7, day: 7, description: "小热时节，温风至", threeHou: ["温风至", "蟋蟀居辟", "鹰乃学习"]),
        UISolarTerm(name: "大暑", season: .summer, month: 7, day: 23, description: "大热时节，酷暑难耐", threeHou: ["腐草为萤", "土润溽暑", "大雨时行"]),

        // 秋季
        UISolarTerm(name: "立秋", season: .autumn, month: 8, day: 8, description: "秋天开始，暑去凉来", threeHou: ["凉风至", "白露降", "寒蝉鸣"]),
        UISolarTerm(name: "处暑", season: .autumn, month: 8, day: 23, description: "暑气渐止，秋意渐浓", threeHou: ["鹰乃祭鸟", "天地始肃", "禾乃登"]),
        UISolarTerm(name: "白露", season: .autumn, month: 9, day: 8, description: "天气转凉，露凝而白", threeHou: ["鸿雁来", "玄鸟归", "群鸟养羞"]),
        UISolarTerm(name: "秋分", season: .autumn, month: 9, day: 23, description: "昼夜平分，秋高气爽", threeHou: ["雷始收声", "蛰虫坯户", "水始涸"]),
        UISolarTerm(name: "寒露", season: .autumn, month: 10, day: 8, description: "露水寒冷，将要凝结", threeHou: ["鸿雁来宾", "雀入大水为蛤", "菊有黄花"]),
        UISolarTerm(name: "霜降", season: .autumn, month: 10, day: 24, description: "天气渐冷，开始降霜", threeHou: ["豺乃祭兽", "草木黄落", "蛰虫咸俯"]),

        // 冬季
        UISolarTerm(name: "立冬", season: .winter, month: 11, day: 7, description: "冬天开始，万物收藏", threeHou: ["水始冰", "地始冻", "雉入大水为蜃"]),
        UISolarTerm(name: "小雪", season: .winter, month: 11, day: 22, description: "开始降雪，但雪量不大", threeHou: ["虹藏不见", "天气上升", "地气下降"]),
        UISolarTerm(name: "大雪", season: .winter, month: 12, day: 7, description: "降雪增多，银装素裹", threeHou: ["鹖旦不鸣", "虎始交", "荔挺出"]),
        UISolarTerm(name: "冬至", season: .winter, month: 12, day: 22, description: "白昼最短，数九开始", threeHou: ["蚯蚓结", "麋角解", "水泉动"]),
        UISolarTerm(name: "小寒", season: .winter, month: 1, day: 6, description: "天气寒冷，但未至极寒", threeHou: ["雁北乡", "鹊始巢", "雉始雊"]),
        UISolarTerm(name: "大寒", season: .winter, month: 1, day: 20, description: "天气寒冷到极致", threeHou: ["鸡始乳", "征鸟厉疾", "水泽腹坚"])
    ]

    // MARK: - 获取当前节气

    static var current: UISolarTerm {
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let day = Calendar.current.component(.day, from: now)

        // 查找当前日期对应的节气
        for solarTerm in allSolarTerms {
            if solarTerm.month == month {
                if let nextTerm = allSolarTerms.first(where: { $0.month > month || ($0.month == month && $0.day > day) }) {
                    // 如果还没到下一个节气，返回当前
                    if day < nextTerm.day {
                        return solarTerm
                    }
                } else {
                    // 年底情况
                    return solarTerm
                }
            }
        }

        // 默认返回小雪（当前季节）
        return UISolarTerm(name: "小雪", season: .winter, month: 11, day: 22, description: "小雪至，冬渐深", threeHou: ["虹藏不见", "天气上升", "地气下降"])
    }
    
    // MARK: - 节气养生建议
    
    var wellnessTips: [String] {
        switch name {
        case "立春":
            return ["宜早睡早起，舒展筋骨", "多食辛甘发散之物", "调畅情志，保持愉悦"]
        case "雨水":
            return ["健脾养胃是关键", "少食生冷油腻", "适度运动，避免过度"]
        case "惊蛰":
            return ["春困时节多休息", "清淡饮食为主", "踏青郊游，舒展身心"]
        case "春分":
            return ["昼夜平衡，规律作息", "多吃时令蔬菜", "风筝运动有益身心"]
        case "清明":
            return ["扫墓踏青，注意情绪", "柔肝养肺为主", "青团适量，不可多食"]
        case "谷雨":
            return ["健脾祛湿正当时", "香椿、槐花正当季", "户外运动，排出湿气"]
        case "立夏":
            return ["养心清热开始", "午睡片刻有益", "少食冰凉，保护脾胃"]
        case "小满":
            return ["健脾祛湿不能停", "苦味食物降心火", "适度运动，忌大汗"]
        case "芒种":
            return ["清热祛湿，健脾养心", "梅子成熟适量食", "避免贪凉，护住阳气"]
        case "夏至":
            return ["养心阴，静心神", "晚睡早起，午休补眠", "绿豆解暑，适量食用"]
        case "小暑":
            return ["避暑防晒是关键", "冬病夏治正当时", "莲子清心，安心入眠"]
        case "大暑":
            return ["防暑降温第一位", "绿豆百合消暑热", "静心养性，避免急躁"]
        case "立秋":
            return ["润肺养阴开始", "少辛多酸，收敛肺气", "早睡早起，滋阴润燥"]
        case "处暑":
            return ["秋燥当道，润肺为先", "银耳百合正当时", "户外运动，增强体质"]
        case "白露":
            return ["昼夜温差大，注意保暖", "龙眼补气血", "秋冻有度，因人而异"]
        case "秋分":
            return ["阴阳平衡，润燥养阴", "秋蟹肥美，适量品尝", "登高望远，舒缓心情"]
        case "寒露":
            return ["寒从脚起，保暖为先", "芝麻蜂蜜润秋燥", "红柿当季，健脾益胃"]
        case "霜降":
            return ["进补养膘正当时", "柿子甘温，健脾止咳", "适度运动，迎接冬天"]
        case "立冬":
            return ["藏精养肾开始", "羊肉萝卜温补肾", "早睡晚起，必待日光"]
        case "小雪":
            return ["温补肾阳，防寒保暖", "黑木耳清血管", "晒太阳，补阳气"]
        case "大雪":
            return ["进补的大好时节", "桂圆红枣暖身心", "冬练三九，适度运动"]
        case "冬至":
            return ["阴极阳生，饺子补身", "羊肉汤暖胃驱寒", "数九开始，护阳养阴"]
        case "小寒":
            return ["腊八粥健脾和胃", "防寒保暖，护住头脚", "早睡晚起，藏养阳气"]
        case "大寒":
            return ["大寒进补，除旧迎新", "八宝粥营养丰富", "安心养性，迎接新春"]
        default:
            return ["顺应时节，调养身心", "规律作息，均衡饮食", "保持愉悦，养生延年"]
        }
    }
}

// Color.init(hex:) 定义在 Design/Theme/ColorExtensions.swift
