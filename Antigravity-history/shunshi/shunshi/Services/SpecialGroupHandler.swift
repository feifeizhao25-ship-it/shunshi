import Foundation

// MARK: - Special Group Handler
/// 特殊人群处理器 - 处理孕妇、哺乳期、经期、儿童/青少年、老年人、慢性病人群、过敏人群
final class SpecialGroupHandler {
    static let shared = SpecialGroupHandler()
    
    private init() {}
    
    // MARK: - 特殊状态枚举
    enum SpecialCondition: Equatable {
        case pregnant              // 孕妇
        case breastfeeding         // 哺乳期
        case menstrual             // 经期
        case minor                 // 未成年
        case elderly               // 老年人
        case chronic(diseases: [String])  // 慢性病
        case allergic(allergens: [String]) // 过敏
        
        var displayName: String {
            switch self {
            case .pregnant: return "孕期"
            case .breastfeeding: return "哺乳期"
            case .menstrual: return "经期"
            case .minor: return "未成年"
            case .elderly: return "老年人"
            case .chronic: return "慢性病"
            case .allergic: return "过敏"
            }
        }
    }
    
    // MARK: - 检测用户特殊状态
    func detectConditions(for user: SpecialGroupUserProfile) -> [SpecialCondition] {
        var conditions: [SpecialCondition] = []
        
        // 孕期/哺乳期/经期
        if let specialPeriod = user.specialPeriod {
            switch specialPeriod {
            case .pregnant:
                conditions.append(.pregnant)
            case .breastfeeding:
                conditions.append(.breastfeeding)
            case .menstrual:
                conditions.append(.menstrual)
            }
        }
        
        // 年龄判断
        if let age = user.age {
            if age < 18 {
                conditions.append(.minor)
            } else if age > 60 {
                conditions.append(.elderly)
            }
        }
        
        // 慢性病
        if !user.chronicDiseases.isEmpty {
            conditions.append(.chronic(diseases: user.chronicDiseases))
        }
        
        // 过敏
        if !user.allergies.isEmpty {
            conditions.append(.allergic(allergens: user.allergies))
        }
        
        return conditions
    }
    
    // MARK: - 过滤不适合的内容
    func filterContent(_ content: String, for user: SpecialGroupUserProfile) -> String {
        var filtered = content
        let conditions = detectConditions(for: user)
        
        for condition in conditions {
            filtered = applyConditionFilter(condition, to: filtered)
        }
        
        return filtered
    }
    
    // MARK: - 添加特殊人群提醒
    func addWarnings(_ response: String, for user: SpecialGroupUserProfile) -> String {
        var warnings: [String] = []
        let conditions = detectConditions(for: user)
        
        if conditions.contains(.pregnant) {
            warnings.append("⚠️ 您处于孕期，部分内容可能不适合，请咨询医生")
        }
        if conditions.contains(.elderly) {
            warnings.append("💡 老年人在尝试新运动或食疗时，建议先咨询医生")
        }
        if let chronic = conditions.first(where: {
            if case .chronic = $0 { return true }
            return false
        }) {
            if case .chronic(let diseases) = chronic {
                warnings.append("💡 由于您有\(diseases.joined(separator: "、"))，养生建议仅供参考，具体请遵医嘱")
            }
        }
        
        guard !warnings.isEmpty else { return response }
        return response + "\n\n" + warnings.joined(separator: "\n")
    }
    
    // MARK: - 检查内容是否适合特定条件
    func isContentSafe(_ content: String, for condition: SpecialCondition) -> Bool {
        switch condition {
        case .pregnant:
            return !PregnantContraindications.containsAny(content)
        case .breastfeeding:
            return !BreastfeedingContraindications.containsAny(content)
        case .menstrual:
            return !MenstrualContraindications.containsAny(content)
        case .minor:
            return !AdultOnlyContent.containsAny(content)
        case .elderly:
            return !HighIntensityContent.containsAny(content)
        case .chronic(let diseases):
            return !ChronicDiseaseContraindications.containsAny(for: diseases, in: content)
        case .allergic(let allergens):
            return !AllergenFilter.containsAny(allergens, in: content)
        }
    }
    
    // MARK: - 生成个性化建议
    func generatePersonalizedAdvice(for condition: SpecialCondition) -> String {
        switch condition {
        case .pregnant:
            return "孕期的养生重点是养血安胎，建议：\n• 保持充足睡眠\n• 均衡饮食，少食多餐\n• 适度散步\n• 避免剧烈运动和提重物"
            
        case .breastfeeding:
            return "哺乳期的养生重点是补气血、通乳汁，建议：\n• 多喝汤水\n• 均衡营养\n• 保持心情愉悦\n• 避免回奶食物"
            
        case .menstrual:
            return "经期的养生重点是温经散寒，建议：\n• 避免受凉\n• 少食生冷\n• 适量运动\n• 保持充足休息"
            
        case .minor:
            return "青少年正处于生长发育期，建议：\n• 保证充足睡眠\n• 均衡饮食\n• 适量运动\n• 养成良好作息习惯"
            
        case .elderly:
            return "老年养生建议：\n• 动作宜缓，避免剧烈运动\n• 保暖防寒\n• 饮食清淡易消化\n• 定期体检"
            
        case .chronic(let diseases):
            return "有\(diseases.joined(separator: "、"))的情况下，日常养生需特别注意：\n• 遵医嘱用药\n• 定期复查\n• 避免诱发因素\n• 保持规律作息"
            
        case .allergic(let allergens):
            return "您对\(allergens.joined(separator: "、"))过敏，日常需注意：\n• 严格避免接触过敏原\n• 随身携带抗过敏药物\n• 了解过敏症状和处理方法"
        }
    }
    
    // MARK: - Private Methods
    private func applyConditionFilter(_ condition: SpecialCondition, to content: String) -> String {
        switch condition {
        case .pregnant:
            return PregnantContraindications.filter(content)
        case .breastfeeding:
            return BreastfeedingContraindications.filter(content)
        case .menstrual:
            return MenstrualContraindications.filter(content)
        case .minor:
            return AdultOnlyContent.filter(content)
        case .elderly:
            return HighIntensityContent.filter(content)
        case .chronic(let diseases):
            return ChronicDiseaseContraindications.filter(diseases: diseases, content: content)
        case .allergic(let allergens):
            return AllergenFilter.filter(allergens: allergens, content: content)
        }
    }
}

// MARK: - 孕妇禁忌配置
struct PregnantContraindications {
    static let acupoints: [String] = ["合谷", "三阴交", "至阴", "昆仑", "肩井", "少腹", "气海"]
    static let foods: [String] = ["山楂", "薏米", "螃蟹", "甲鱼", "桂圆", "马齿苋", "杏仁", "芦荟", "桂皮", "当归"]
    static let teas: [String] = ["红花茶", "益母草茶", "藏红花茶", "玫瑰花茶", "桃花茶"]
    static let exercises: [String] = ["剧烈运动", "仰卧起坐", "跳跃类", "跑步", "游泳", "骑行"]
    
    static func containsAny(_ content: String) -> Bool {
        acupoints.contains { content.contains($0) } ||
        foods.contains { content.contains($0) } ||
        teas.contains { content.contains($0) } ||
        exercises.contains { content.contains($0) }
    }
    
    static func filter(_ content: String) -> String {
        var filtered = content
        for acupoint in acupoints {
            filtered = filtered.replacingOccurrences(of: acupoint, with: "⚠️\(acupoint)⚠️")
        }
        for food in foods {
            filtered = filtered.replacingOccurrences(of: food, with: "⚠️\(food)⚠️")
        }
        for tea in teas {
            filtered = filtered.replacingOccurrences(of: tea, with: "⚠️\(tea)⚠️")
        }
        return filtered
    }
}

// MARK: - 哺乳期禁忌
struct BreastfeedingContraindications {
    static let foods: [String] = ["麦芽", "韭菜", "花椒", "辣椒", "咖啡", "浓茶", "酒精"]
    
    static func containsAny(_ content: String) -> Bool {
        foods.contains { content.contains($0) }
    }
    
    static func filter(_ content: String) -> String {
        var filtered = content
        for food in foods {
            filtered = filtered.replacingOccurrences(of: food, with: "⚠️\(food)⚠️")
        }
        return filtered
    }
}

// MARK: - 经期禁忌
struct MenstrualContraindications {
    static let foods: [String] = ["冰激凌", "冷饮", "生冷", "西瓜", "梨", "螃蟹"]
    
    static func containsAny(_ content: String) -> Bool {
        foods.contains { content.contains($0) }
    }
    
    static func filter(_ content: String) -> String {
        var filtered = content
        for food in foods {
            filtered = filtered.replacingOccurrences(of: food, with: "⚠️\(food)⚠️")
        }
        return filtered
    }
}

// MARK: - 成人内容过滤
struct AdultOnlyContent {
    static let keywords: [String] = ["减肥药", "医美", "整形", "美容针"]
    
    static func containsAny(_ content: String) -> Bool {
        keywords.contains { content.contains($0) }
    }
    
    static func filter(_ content: String) -> String {
        return "这部分内容暂时不适合你哦~等你长大再看吧！🌱"
    }
}

// MARK: - 高强度内容（老年人慎用）
struct HighIntensityContent {
    static let keywords: [String] = ["高强度", "剧烈运动", "HIIT", "跑步5公里", "马拉松", "极限运动"]
    
    static func containsAny(_ content: String) -> Bool {
        keywords.contains { content.contains($0) }
    }
    
    static func filter(_ content: String) -> String {
        return content.replacingOccurrences(of: "高强度", with: "温和")
            .replacingOccurrences(of: "剧烈", with: "适度")
    }
}

// MARK: - 慢性病禁忌
struct ChronicDiseaseContraindications {
    static let diseaseKeywords: [String: [String]] = [
        "糖尿病": ["糖", "甜食", "蛋糕", "蜂蜜", "荔枝", "芒果"],
        "高血压": ["盐", "咸菜", "腊肉", "咖啡因", "浓茶"],
        "心脏病": ["咖啡", "浓茶", "辣椒", "动物内脏"],
        "肾病": ["高蛋白", "豆制品", "杨桃", "海鲜"]
    ]
    
    static func containsAny(for diseases: [String], in content: String) -> Bool {
        for disease in diseases {
            if let keywords = diseaseKeywords[disease] {
                if keywords.contains(where: { content.contains($0) }) {
                    return true
                }
            }
        }
        return false
    }
    
    static func filter(diseases: [String], content: String) -> String {
        var filtered = content
        for disease in diseases {
            if let keywords = diseaseKeywords[disease] {
                for keyword in keywords {
                    filtered = filtered.replacingOccurrences(of: keyword, with: "⚠️\(keyword)⚠️")
                }
            }
        }
        return filtered
    }
}

// MARK: - 过敏原过滤器
struct AllergenFilter {
    static func containsAny(_ allergens: [String], in content: String) -> Bool {
        allergens.contains { content.contains($0) }
    }
    
    static func filter(allergens: [String], content: String) -> String {
        var filtered = content
        for allergen in allergens {
            filtered = filtered.replacingOccurrences(of: allergen, with: "⚠️\(allergen)⚠️")
        }
        return filtered
    }
}

// MARK: - 服务层用户档案 (用于特殊人群检测)
struct SpecialGroupUserProfile {
    let id: String
    var age: Int?
    var gender: String?
    var specialPeriod: SpecialPeriod?
    var chronicDiseases: [String]
    var allergies: [String]

    enum SpecialPeriod: String {
        case pregnant
        case breastfeeding
        case menstrual
    }

    init(id: String) {
        self.id = id
        self.age = nil
        self.gender = nil
        self.specialPeriod = nil
        self.chronicDiseases = []
        self.allergies = []
    }
}

// MARK: - AI边界检测扩展
extension AIAgentService {
    /// 检查并过滤特殊人群不适宜的内容
    func checkSpecialGroupSafety(userInput: String, user: SpecialGroupUserProfile) -> (isSafe: Bool, warning: String?) {
        let conditions = SpecialGroupHandler.shared.detectConditions(for: user)
        
        for condition in conditions {
            if !SpecialGroupHandler.shared.isContentSafe(userInput, for: condition) {
                let warning = "您处于\(condition.displayName)，这个问题可能需要特别注意。建议咨询专业医生获取更准确的建议哦~"
                return (false, warning)
            }
        }
        
        return (true, nil)
    }
}
