import Foundation
import Combine

// MARK: - Constitution Service
/// 体质辨识与调理服务 - 管理体质测试、档案、方案等功能
final class ConstitutionService: ObservableObject {
    static let shared = ConstitutionService()
    
    // MARK: - 九种体质定义
    let constitutions: [ServiceConstitution] = [
        ServiceConstitution(
            id: "qiXu",
            name: "气虚质",
            emoji: "🍃",
            description: "元气不足，疲乏无力",
            characteristics: ["容易疲劳", "语声低弱", "气短懒言", "易出汗"],
            dietRecommendations: ["山药", "黄芪", "大枣", "小米", "牛肉"],
            dietAvoid: ["生冷", "油腻", "萝卜"],
            teaRecommendations: ["黄芪红枣茶", "党参枸杞茶"],
            acupoints: ["足三里", "气海", "关元"],
            exerciseAdvice: "八段锦、散步、太极，避免剧烈运动"
        ),
        ServiceConstitution(
            id: "yangXu",
            name: "阳虚质",
            emoji: "❄️",
            description: "阳气不足，畏寒怕冷",
            characteristics: ["畏寒怕冷", "手足不温", "喜热饮食", "精神不振"],
            dietRecommendations: ["羊肉", "桂圆", "生姜", "核桃", "韭菜"],
            dietAvoid: ["生冷", "冰饮", "寒性食物"],
            teaRecommendations: ["桂圆红枣茶", "生姜红糖茶"],
            acupoints: ["关元", "命门", "肾俞"],
            exerciseAdvice: "温和运动如散步、太极，避免大汗淋漓"
        ),
        ServiceConstitution(
            id: "yinXu",
            name: "阴虚质",
            emoji: "🔥",
            description: "阴液不足，口干手热",
            characteristics: ["口燥咽干", "手足心热", "喜冷饮", "大便干结"],
            dietRecommendations: ["银耳", "百合", "梨", "蜂蜜", "枸杞"],
            dietAvoid: ["辛辣", "油炸", "羊肉", "姜葱蒜"],
            teaRecommendations: ["麦冬菊花茶", "百合枸杞茶"],
            acupoints: ["太溪", "涌泉", "三阴交"],
            exerciseAdvice: "太极、静坐、瑜伽，避免剧烈运动"
        ),
        ServiceConstitution(
            id: "tanShi",
            name: "痰湿质",
            emoji: "💧",
            description: "痰湿内蕴，体胖黏腻",
            characteristics: ["形体肥胖", "腹部肥满", "面部皮肤油脂多", "痰多"],
            dietRecommendations: ["薏米", "冬瓜", "赤小豆", "白萝卜", "荷叶"],
            dietAvoid: ["甜腻", "油炸", "冷饮", "酒"],
            teaRecommendations: ["陈皮普洱", "荷叶山楂茶"],
            acupoints: ["丰隆", "足三里", "中脘"],
            exerciseAdvice: "加大运动量，快走、游泳、球类运动"
        ),
        ServiceConstitution(
            id: "shiRe",
            name: "湿热质",
            emoji: "🌡️",
            description: "湿热内蕴，面垢油光",
            characteristics: ["面垢油光", "易生痤疮", "口苦口臭", "大便黏滞"],
            dietRecommendations: ["绿豆", "苦瓜", "芹菜", "薏米", "莲藕"],
            dietAvoid: ["辛辣", "油炸", "羊肉", "酒"],
            teaRecommendations: ["菊花绿茶", "金银花茶"],
            acupoints: ["阴陵泉", "曲池", "太冲"],
            exerciseAdvice: "大运动量运动，如跑步、游泳"
        ),
        ServiceConstitution(
            id: "xueYu",
            name: "血瘀质",
            emoji: "🩸",
            description: "血行不畅，色斑疼痛",
            characteristics: ["面色晦暗", "易出现瘀斑", "唇色偏暗", "健忘"],
            dietRecommendations: ["山楂", "黑木耳", "玫瑰花", "红花", "桃仁"],
            dietAvoid: ["寒凉", "收涩", "油腻"],
            teaRecommendations: ["山楂玫瑰茶", "桃红四物茶"],
            acupoints: ["血海", "膈俞", "太冲"],
            exerciseAdvice: "促进血液循环的运动，如舞蹈、太极"
        ),
        ServiceConstitution(
            id: "qiYu",
            name: "气郁质",
            emoji: "🌧️",
            description: "气机郁结，抑郁脆弱",
            characteristics: ["情绪低沉", "善太息", "咽中异物感", "胸胁胀满"],
            dietRecommendations: ["佛手", "香橼", "玫瑰花", "茉莉花", "橙子"],
            dietAvoid: ["收敛", "壅滞", "生冷"],
            teaRecommendations: ["玫瑰花茶", "佛手陈皮茶"],
            acupoints: ["太冲", "膻中", "期门"],
            exerciseAdvice: "放松身心的运动，如瑜伽、太极、户外活动"
        ),
        ServiceConstitution(
            id: "teBing",
            name: "特禀质",
            emoji: "🌸",
            description: "先天失常，过敏反应",
            characteristics: ["过敏体质", "遗传疾病", "胎传疾病", "适应能力差"],
            dietRecommendations: ["根据过敏原避免", "均衡饮食", "健脾益气"],
            dietAvoid: ["已知过敏原", "辛辣", "发物"],
            teaRecommendations: ["根据体质选择", "固表茶"],
            acupoints: ["足三里", "关元", "肺俞"],
            exerciseAdvice: "根据自身情况选择温和运动"
        ),
        ServiceConstitution(
            id: "pingHe",
            name: "平和质",
            emoji: "☀️",
            description: "阴阳调和，健康体质",
            characteristics: ["面色红润", "精力充沛", "睡眠良好", "适应能力强"],
            dietRecommendations: ["均衡饮食", "五谷为养", "五果为助"],
            dietAvoid: ["无特殊禁忌", "避免偏食"],
            teaRecommendations: ["四季养生茶", "普洱"],
            acupoints: ["足三里", "涌泉", "三阴交"],
            exerciseAdvice: "坚持运动，保持良好生活习惯"
        )
    ]
    
    // MARK: - 用户体质状态
    @Published var userProfile: ServiceUserConstitutionProfile?
    @Published var testHistory: [ServiceConstitutionTestRecord] = []
    @Published var currentTestSession: TestSession?
    
    // MARK: - 测试配置
    let testConfig = TestConfiguration(
        quickVersion: TestVersion(
            name: "快速版",
            questionCount: 10,
            duration: 2, // 分钟
            description: "2分钟快速了解体质倾向"
        ),
        standardVersion: TestVersion(
            name: "标准版",
            questionCount: 25,
            duration: 5,
            description: "5分钟获得准确体质判定"
        ),
        deepVersion: TestVersion(
            name: "深度版",
            questionCount: 40,
            duration: 10,
            description: "10分钟获得详细体质分析（付费）"
        )
    )
    
    private init() {
        loadUserProfile()
    }
    
    // MARK: - 加载用户档案
    private func loadUserProfile() {
        // 从本地加载
        if let data = UserDefaults.standard.data(forKey: "user_constitution_profile"),
           let profile = try? JSONDecoder().decode(ServiceUserConstitutionProfile.self, from: data) {
            self.userProfile = profile
        }
        
        // 加载测试历史
        if let data = UserDefaults.standard.data(forKey: "user_constitution_history"),
           let history = try? JSONDecoder().decode([ServiceConstitutionTestRecord].self, from: data) {
            self.testHistory = history
        }
    }
    
    // MARK: - 开始测试
    func startTest(mode: TestMode, userId: String) -> TestSession {
        let questionCount: Int
        switch mode {
        case .quick: questionCount = testConfig.quickVersion.questionCount
        case .standard: questionCount = testConfig.standardVersion.questionCount
        case .deep: questionCount = testConfig.deepVersion.questionCount
        }
        
        let session = TestSession(
            id: UUID().uuidString,
            userId: userId,
            mode: mode,
            questions: generateQuestions(count: questionCount),
            currentIndex: 0,
            answers: [:],
            startedAt: Date()
        )
        
        currentTestSession = session
        return session
    }
    
    // MARK: - 生成测试题目
    private func generateQuestions(count: Int) -> [TestQuestion] {
        // 基于《中医体质分类与判定》标准题库
        let allQuestions: [TestQuestion] = [
            TestQuestion(id: "1", text: "您容易疲乏吗？", dimension: .qiXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "2", text: "您容易气短吗？", dimension: .qiXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "3", text: "您容易心慌吗？", dimension: .qiXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "4", text: "您容易头晕吗？", dimension: .qiXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "5", text: "您比同龄人怕冷吗？", dimension: .yangXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "6", text: "您手脚冰凉吗？", dimension: .yangXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "7", text: "您胃脘部怕冷吗？", dimension: .yangXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "8", text: "您口干咽燥吗？", dimension: .yinXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "9", text: "您手足心热吗？", dimension: .yinXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            TestQuestion(id: "10", text: "您大便干结吗？", dimension: .yinXu, options: [
                TestOption(text: "经常", score: 5),
                TestOption(text: "偶尔", score: 3),
                TestOption(text: "很少", score: 1)
            ]),
            // 更多题目...
        ]
        
        return Array(allQuestions.prefix(count))
    }
    
    // MARK: - 提交测试
    func submitTest(session: TestSession) -> ConstitutionResult {
        // 计算各维度分数
        var dimensionScores: [ConstitutionDimension: Double] = [:]
        
        for (questionId, answer) in session.answers {
            guard let question = session.questions.first(where: { $0.id == questionId }),
                  let selectedOption = question.options.first(where: { $0.text == answer }) else {
                continue
            }
            
            let currentScore = dimensionScores[question.dimension] ?? 0
            dimensionScores[question.dimension] = currentScore + Double(selectedOption.score)
        }
        
        // 判定体质类型
        let primaryDimension = dimensionScores.max(by: { $0.value < $1.value })?.key ?? .qiXu
        let secondaryDimension = dimensionScores.sorted(by: { $0.value > $1.value }).dropFirst().first?.key
        
        // 计算平和度
        let pingheScore = calculatePingheScore(dimensions: dimensionScores)
        
        let result = ConstitutionResult(
            id: UUID().uuidString,
            testDate: Date(),
            primaryConstitution: primaryDimension,
            secondaryConstitution: secondaryDimension,
            scores: dimensionScores,
            pingheScore: pingheScore,
            recommendations: generateRecommendations(for: primaryDimension)
        )
        
        // 5. 保存结果
        saveTestResult(result, session: session)
        
        return result
    }
    
    private func calculatePingheScore(dimensions: [ConstitutionDimension: Double]) -> Double {
        // 平和度计算：各偏颇体质分数越低，平和度越高
        let totalScore = dimensions.values.reduce(0, +)
        let maxPossible = Double(dimensions.count * 5) // Assuming max score per question is 5
        return max(0, (1 - totalScore / maxPossible) * 100)
    }
    
    // MARK: - 生成建议
    private func generateRecommendations(for dimension: ConstitutionDimension) -> ServiceConstitutionRecommendations {
        let constitution = constitutions.first(where: { $0.id == dimension.rawValue })
        
        guard let target = constitution else {
            return ServiceConstitutionRecommendations(diet: [], tea: [], acupoints: [], exercises: [], tips: [])
        }
        
        return ServiceConstitutionRecommendations(
            diet: target.dietRecommendations,
            tea: target.teaRecommendations,
            acupoints: target.acupoints,
            exercises: [target.exerciseAdvice],
            tips: target.characteristics
        )
    }
    
    // MARK: - 生成调理任务
    func generateConditioningTasks(for result: ConstitutionResult) -> [ServiceDailyTask] {
        let tasks: [ServiceDailyTask] = (1...21).map { day in
            ServiceDailyTask(
                id: "day\(day)", // Added id to match ServiceDailyTask
                title: "\(result.primaryConstitution.displayName)调理 - 第\(day)天",
                description: "根据您的\(result.primaryConstitution.displayName)体质，今日建议：\(result.recommendations.diet.first ?? "平衡膳食")。",
                points: 20,
                isCompleted: false // Added isCompleted to match ServiceDailyTask
            )
        }
        return tasks
    }
    
    func saveTestResult(_ result: ConstitutionResult, session: TestSession) {
        // 保存到历史记录
        let record = ServiceConstitutionTestRecord(
            id: result.id,
            date: result.testDate,
            mode: session.mode.rawValue,
            primaryConstitution: result.primaryConstitution.displayName,
            score: result.pingheScore
        )
        testHistory.append(record)
        
        // 更新用户档案
        if userProfile == nil {
            userProfile = ServiceUserConstitutionProfile(userId: session.userId)
        }
        userProfile?.currentResult = result
        userProfile?.lastTestDate = result.testDate
        userProfile?.testHistory = testHistory
        userProfile?.nextRecommendedTestDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) // Added this line back
        
        // 持久化
        if let profileData = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(profileData, forKey: "user_constitution_profile")
        }
        if let historyData = try? JSONEncoder().encode(testHistory) {
            UserDefaults.standard.set(historyData, forKey: "constitution_test_history") // Changed key to match loadUserProfile
        }
    }
    
    // MARK: - 获取21天计划
    func get21DayPlan(for constitutionId: String) -> TwentyOneDayPlan {
        let constitution = constitutions.first(where: { $0.id == constitutionId })
        
        let tasks: [ServiceDailyTask] = (1...21).map { day in
            let dayTasks = [
                "早餐吃推荐的养生食材",
                "喝一杯调理茶饮",
                "按揉养生穴位3分钟",
                "完成15分钟养生运动",
                "早睡22:00前入睡",
                "记录今日养生心得"
            ]
            
            return ServiceDailyTask(
                id: "day\(day)",
                title: "第\(day)天: \(constitution?.name ?? "体质")调理",
                description: dayTasks.randomElement() ?? "平衡膳食",
                points: 10,
                isCompleted: false
            )
        }
        
        return TwentyOneDayPlan(
            constitution: constitution?.name ?? "通用",
            days: tasks,
            dailyGoals: [
                "坚持完成每日任务",
                "记录养生感受",
                "养成良好习惯"
            ]
        )
    }
}

// MARK: - 服务层体质定义 (避免与Domain层Constitution冲突)
struct ServiceConstitution {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let characteristics: [String]
    let dietRecommendations: [String]
    let dietAvoid: [String]
    let teaRecommendations: [String]
    let acupoints: [String]
    let exerciseAdvice: String
}

// MARK: - 体质维度
enum ConstitutionDimension: String, CaseIterable, Codable {
    case qiXu = "qiXu"
    case yangXu = "yangXu"
    case yinXu = "yinXu"
    case tanShi = "tanShi"
    case shiRe = "shiRe"
    case xueYu = "xueYu"
    case qiYu = "qiYu"
    case teBing = "teBing"
    case pingHe = "pingHe"
    
    var displayName: String {
        switch self {
        case .qiXu: return "气虚质"
        case .yangXu: return "阳虚质"
        case .yinXu: return "阴虚质"
        case .tanShi: return "痰湿质"
        case .shiRe: return "湿热质"
        case .xueYu: return "血瘀质"
        case .qiYu: return "气郁质"
        case .teBing: return "特禀质"
        case .pingHe: return "平和质"
        }
    }

    var emoji: String {
        switch self {
        case .qiXu: return "🍃"
        case .yangXu: return "❄️"
        case .yinXu: return "🔥"
        case .tanShi: return "💧"
        case .shiRe: return "🌡️"
        case .xueYu: return "🩸"
        case .qiYu: return "🌧️"
        case .teBing: return "🌸"
        case .pingHe: return "☀️"
        }
    }
}

// MARK: - 测试配置
struct TestConfiguration {
    let quickVersion: TestVersion
    let standardVersion: TestVersion
    let deepVersion: TestVersion
}

struct TestVersion {
    let name: String
    let questionCount: Int
    let duration: Int // 分钟
    let description: String
}

// MARK: - 测试模式
enum TestMode: String {
    case quick = "quick"
    case standard = "standard"
    case deep = "deep"
}

// MARK: - 测试会话
struct TestSession {
    let id: String
    let userId: String
    let mode: TestMode
    let questions: [TestQuestion]
    var currentIndex: Int
    var answers: [String: String]
    let startedAt: Date
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(answers.count) / Double(questions.count)
    }
    
    var isComplete: Bool {
        return answers.count == questions.count
    }
    
    var currentQuestion: TestQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
}

// MARK: - 测试题目
struct TestQuestion: Identifiable {
    let id: String
    let text: String
    let dimension: ConstitutionDimension
    let options: [TestOption]
}

struct TestOption: Identifiable {
    let id = UUID()
    let text: String
    let score: Int
}

// MARK: - 测试结果 (使用服务层专用类型)
struct ConstitutionResult: Codable {
    let id: String
    let testDate: Date
    let primaryConstitution: ConstitutionDimension
    let secondaryConstitution: ConstitutionDimension?
    let scores: [ConstitutionDimension: Double]
    let pingheScore: Double
    let recommendations: ServiceConstitutionRecommendations
}

struct ServiceConstitutionRecommendations: Codable {
    let diet: [String]
    let tea: [String]
    let acupoints: [String]
    let exercises: [String]
    let tips: [String]
}

// MARK: - 21天计划
struct TwentyOneDayPlan {
    let constitution: String
    let days: [ServiceDailyTask]
    let dailyGoals: [String]

    var completionRate: Double {
        let completed = days.filter { $0.isCompleted }.count
        return Double(completed) / Double(days.count)
    }
}

// MARK: - 体质筛选服务
class ConstitutionFilterService {
    static let shared = ConstitutionFilterService()

    // 筛选适合特定体质的食谱
    func filterRecipes<T>(recipes: [T], for constitutionId: String) -> [T] {
        // TODO: 根据体质ID筛选适合的食谱
        return recipes
    }

    // 检查食物是否适合用户
    func isFoodSuitable(food: String, for constitutionId: String) -> SuitabilityResult {
        let constitution = ConstitutionService.shared.constitutions
            .first(where: { $0.id == constitutionId })

        guard let target = constitution else {
            return SuitabilityResult(status: .unknown, message: "未检测体质")
        }

        if target.dietRecommendations.contains(food) {
            return SuitabilityResult(status: .recommended, message: "推荐食用")
        }

        if target.dietAvoid.contains(food) {
            return SuitabilityResult(status: .avoid, message: "建议少吃或避免")
        }

        return SuitabilityResult(status: .neutral, message: "适量即可")
    }
}

struct SuitabilityResult {
    let status: SuitabilityStatus
    let message: String
    
    enum SuitabilityStatus {
        case recommended
        case neutral
        case avoid
        case unknown
    }
}

// MARK: - 用户体质档案 (服务层专用)
struct ServiceUserConstitutionProfile: Codable {
    let userId: String
    var currentResult: ConstitutionResult?
    var lastTestDate: Date?
    var nextRecommendedTestDate: Date?
    var testHistory: [ServiceConstitutionTestRecord] = []

    var primaryConstitution: String {
        currentResult?.primaryConstitution.displayName ?? "未检测"
    }

    var constitutionEmoji: String {
        guard let result = currentResult else { return "❓" }
        let constitutions = ConstitutionService.shared.constitutions
        return constitutions.first(where: { $0.id == result.primaryConstitution.rawValue })?.emoji ?? "❓"
    }
}

// MARK: - 体质报告生成服务
class ConstitutionReportService {
    static let shared = ConstitutionReportService()

    func generateReport(for profile: ServiceUserConstitutionProfile) -> ReportData {
        guard let result = profile.currentResult else {
            return ReportData(title: "暂无体质数据", sections: [])
        }

        let constitution = ConstitutionService.shared.constitutions
            .first(where: { $0.id == result.primaryConstitution.rawValue })

        let sections = [
            ReportSection(title: "体质判定", content: result.primaryConstitution.displayName),
            ReportSection(title: "体质特征", content: constitution?.characteristics.joined(separator: "、") ?? ""),
            ReportSection(title: "饮食建议", content: constitution?.dietRecommendations.joined(separator: "、") ?? ""),
            ReportSection(title: "运动建议", content: constitution?.exerciseAdvice ?? "")
        ]

        return ReportData(
            title: "\(result.primaryConstitution.displayName)体质报告",
            sections: sections
        )
    }
}

struct ReportData {
    let title: String
    let sections: [ReportSection]
}

struct ReportSection {
    let title: String
    let content: String
}
