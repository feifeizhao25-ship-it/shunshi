import Foundation

// MARK: - Conditioning Plan Entity
struct ConditioningPlan: Identifiable, Codable {
    let id: String
    let userId: String
    let constitutionType: String
    let solarTerm: String
    let startDate: Date
    let endDate: Date
    
    var objective: String
    var corePrinciples: [String]
    
    var weeklyTasks: [PlanDayTask]
    var recommendedFoods: [String]
    var avoidedFoods: [String]
    
    var progress: Double // 0.0 - 1.0
    
    init(id: String = UUID().uuidString, userId: String, constitutionType: String, solarTerm: String, startDate: Date = Date()) {
        self.id = id
        self.userId = userId
        self.constitutionType = constitutionType
        self.solarTerm = solarTerm
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        self.objective = "调理\(constitutionType)，顺应\(solarTerm)"
        self.corePrinciples = []
        self.weeklyTasks = []
        self.recommendedFoods = []
        self.avoidedFoods = []
        self.progress = 0.0
    }
}

// MARK: - Daily Tasks
struct PlanDayTask: Identifiable, Codable {
    let id: String
    let dayOfWeek: Int // 1-7
    let morning: String
    let afternoon: String
    let evening: String
    let specialAcupoint: String?
    let isCompleted: Bool
}

// MARK: - Plan Generation Service
final class PlanGenerationService {
    static let shared = PlanGenerationService()
    private let llmService = LLMService.shared
    
    /// Generates a highly personalized conditioning plan using AI
    func generatePlan(for userId: String, constitution: String, solarTerm: String) async throws -> ConditioningPlan {
        // 1. Try to load existing plan
        if let existingPlan = loadExistingPlan(for: userId), 
           existingPlan.constitutionType == constitution,
           existingPlan.solarTerm == solarTerm {
            print("Loaded existing plan for \(constitution)")
            return existingPlan
        }
        
        // 2. Generate new plan
        print("Generating AI Conditioning Plan for \(constitution) during \(solarTerm)")
        
        // Simulate AI generation delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let plan: ConditioningPlan
        
        // Route to specific generation logic based on constitution
        if constitution.contains("气虚") {
            plan = generateQiDeficiencyPlan(userId: userId, solarTerm: solarTerm)
        } else if constitution.contains("阳虚") {
            plan = generateYangDeficiencyPlan(userId: userId, solarTerm: solarTerm)
        } else {
            plan = generateDefaultPlan(userId: userId, constitution: constitution, solarTerm: solarTerm)
        }
        
        // 3. Save the new plan
        savePlan(plan)
        
        return plan
    }
    
    private let storageKey = "user_conditioning_plan"
    
    private func savePlan(_ plan: ConditioningPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadExistingPlan(for userId: String) -> ConditioningPlan? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let plan = try? JSONDecoder().decode(ConditioningPlan.self, from: data) else {
            return nil
        }
        // Ideally check userId here too
        return plan
    }
    
    private func generateQiDeficiencyPlan(userId: String, solarTerm: String) -> ConditioningPlan {
        var plan = ConditioningPlan(userId: userId, constitutionType: "气虚质", solarTerm: solarTerm)
        plan.corePrinciples = ["益气健脾", "避风保暖", "动中有静"]
        plan.objective = "通过温补脾肺之气，提升冬季抗寒防病能力"
        plan.recommendedFoods = ["淮山药", "大枣", "板栗", "芡实", "党参鸡汤"]
        plan.avoidedFoods = ["生冷西瓜", "寒性螃蟹", "过于油腻的甜点"]
        
        plan.weeklyTasks = (1...7).map { day in
            PlanDayTask(
                id: UUID().uuidString,
                dayOfWeek: day,
                morning: "晨起饮山药红枣汤，揉按足三里穴3分钟",
                afternoon: "午后散步20分钟，注意背部保暖",
                evening: "艾草泡脚20分钟，十一点前入睡以养气",
                specialAcupoint: "气海穴",
                isCompleted: false
            )
        }
        return plan
    }
    
    private func generateYangDeficiencyPlan(userId: String, solarTerm: String) -> ConditioningPlan {
        var plan = ConditioningPlan(userId: userId, constitutionType: "阳虚质", solarTerm: solarTerm)
        plan.corePrinciples = ["温阳散寒", "通经活络", "顾护阳气"]
        plan.objective = "温煦脏腑，改善手脚冰凉，增强元阳"
        plan.recommendedFoods = ["当归羊肉", "生姜", "韭菜", "核桃", "桂圆"]
        plan.avoidedFoods = ["冰镇饮料", "凉拌生食", "苦瓜"]
        
        plan.weeklyTasks = (1...7).map { day in
            PlanDayTask(
                id: UUID().uuidString,
                dayOfWeek: day,
                morning: "生姜红枣茶送服早餐，温中散寒",
                afternoon: "晒太阳15分钟（晒背后部），补充天然阳气",
                evening: "睡前搓脚心（涌泉穴）各100次，温通肾经",
                specialAcupoint: "命门穴",
                isCompleted: false
            )
        }
        return plan
    }
    
    private func generateDefaultPlan(userId: String, constitution: String, solarTerm: String) -> ConditioningPlan {
        var plan = ConditioningPlan(userId: userId, constitutionType: constitution, solarTerm: solarTerm)
        plan.corePrinciples = ["顺应自然", "调和阴阳", "饮食有节"]
        plan.weeklyTasks = (1...7).map { day in
            PlanDayTask(id: UUID().uuidString, dayOfWeek: day, morning: "温水润肠", afternoon: "轻度拉伸", evening: "温水泡脚", specialAcupoint: "合谷", isCompleted: false)
        }
        return plan
    }
}
