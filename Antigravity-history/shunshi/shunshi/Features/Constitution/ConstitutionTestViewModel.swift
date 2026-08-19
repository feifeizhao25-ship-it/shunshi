import Foundation
import SwiftUI

// MARK: - Constitution Test ViewModel
@MainActor
final class ConstitutionTestViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var selectedOption: ConstitutionOption?
    @Published var answers: [ConstitutionOption] = []
    @Published var isCompleted: Bool = false
    @Published var resultType: ConstitutionType?
    
    // Properties expected by ConstitutionTestView
    @Published var showTest: Bool = false
    @Published var showProfile: Bool = false
    @Published var selectedMode: TestMode = .quick
    @Published var existingResult: ConstitutionResult?
    
    var hasExistingResult: Bool {
        existingResult != nil
    }
    
    var nextTestDate: String? {
        guard existingResult != nil else { return nil }
        let date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    func shareResult() {
        // TODO: Implement sharing
    }

    let questions: [ConstitutionQuestion] = ConstitutionQuestion.allQuestions

    var totalQuestions: Int { questions.count }

    var currentQuestion: ConstitutionQuestion {
        questions[currentIndex]
    }

    var progress: Double {
        Double(currentIndex) / Double(totalQuestions)
    }

    // MARK: - Select Option
    func selectOption(_ option: ConstitutionOption) {
        selectedOption = option

        // Auto advance after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.nextQuestion()
        }
    }

    // MARK: - Next Question
    func nextQuestion() {
        guard let selected = selectedOption else { return }

        answers.append(selected)
        selectedOption = nil

        if currentIndex < totalQuestions - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            calculateResult()
        }
    }

    // MARK: - Calculate Result
    private func calculateResult() {
        var scores: [ConstitutionType: Int] = [:]

        for (index, answer) in answers.enumerated() {
            let question = questions[index]
            let type = question.constitutionType
            scores[type, default: 0] += answer.score
        }

        // Find the constitution type with highest score
        let sortedScores = scores.sorted { $0.value > $1.value }
        guard let topType = sortedScores.first?.key else { return }

        resultType = topType

        withAnimation {
            isCompleted = true
        }

        // Track analytics
        AnalyticsService.shared.trackEvent(.constitutionTestComplete, parameters: [
            "constitution_type": topType.rawValue
        ])
    }

    // MARK: - Result Helpers
    var dietRecommendations: [String] {
        guard let type = resultType else { return [] }
        return ConstitutionRecommendationData.diet[type] ?? []
    }

    var exerciseRecommendations: [String] {
        guard let type = resultType else { return [] }
        return ConstitutionRecommendationData.exercise[type] ?? []
    }

    var emotionRecommendations: [String] {
        guard let type = resultType else { return [] }
        return ConstitutionRecommendationData.emotion[type] ?? []
    }
}

// MARK: - Constitution Option
enum ConstitutionOption: CaseIterable {
    case never
    case rarely
    case sometimes
    case often
    case always

    var displayText: String {
        switch self {
        case .never: return "从不"
        case .rarely: return "很少"
        case .sometimes: return "有时"
        case .often: return "经常"
        case .always: return "总是"
        }
    }

    var score: Int {
        switch self {
        case .never: return 1
        case .rarely: return 2
        case .sometimes: return 3
        case .often: return 4
        case .always: return 5
        }
    }
}

// MARK: - Constitution Question
struct ConstitutionQuestion {
    let text: String
    let constitutionType: ConstitutionType

    static let allQuestions: [ConstitutionQuestion] = [
        // 气虚质 (Qi Deficiency)
        ConstitutionQuestion(text: "您容易感到疲乏吗？", constitutionType: .qiDeficiency),
        ConstitutionQuestion(text: "您容易气短、呼吸短促吗？", constitutionType: .qiDeficiency),
        ConstitutionQuestion(text: "您说话声音低弱无力吗？", constitutionType: .qiDeficiency),
        ConstitutionQuestion(text: "您容易出汗吗（自汗）？", constitutionType: .qiDeficiency),
        ConstitutionQuestion(text: "您容易感冒吗？", constitutionType: .qiDeficiency),
        ConstitutionQuestion(text: "您容易感到头晕或目眩吗？", constitutionType: .qiDeficiency),

        // 阳虚质 (Yang Deficiency)
        ConstitutionQuestion(text: "您手脚发凉吗？", constitutionType: .yangDeficiency),
        ConstitutionQuestion(text: "您怕冷，穿的衣服总比别人多吗？", constitutionType: .yangDeficiency),
        ConstitutionQuestion(text: "您受凉或吃冷的东西后容易拉肚子吗？", constitutionType: .yangDeficiency),
        ConstitutionQuestion(text: "您感到背部怕冷吗？", constitutionType: .yangDeficiency),
        ConstitutionQuestion(text: "您感到腰膝部怕冷吗？", constitutionType: .yangDeficiency),
        ConstitutionQuestion(text: "您吃（喝）凉的东西后感到不舒服吗？", constitutionType: .yangDeficiency),

        // 阴虚质 (Yin Deficiency)
        ConstitutionQuestion(text: "您感到手脚心发热吗？", constitutionType: .yinDeficiency),
        ConstitutionQuestion(text: "您感到身体、脸上发热吗？", constitutionType: .yinDeficiency),
        ConstitutionQuestion(text: "您口干咽燥吗？", constitutionType: .yinDeficiency),
        ConstitutionQuestion(text: "您感到眼睛干涩吗？", constitutionType: .yinDeficiency),
        ConstitutionQuestion(text: "您感到皮肤干燥吗？", constitutionType: .yinDeficiency),
        ConstitutionQuestion(text: "您会有大便干燥的情况吗？", constitutionType: .yinDeficiency),

        // 痰湿质 (Phlegm-Dampness)
        ConstitutionQuestion(text: "您感到胸闷或腹部胀满吗？", constitutionType: .phlegmDampness),
        ConstitutionQuestion(text: "您身体肥胖，腹部肥满松软吗？", constitutionType: .phlegmDampness),
        ConstitutionQuestion(text: "您有额头部油脂分泌多的现象吗？", constitutionType: .phlegmDampness),
        ConstitutionQuestion(text: "您感到身体沉重、不轻松吗？", constitutionType: .phlegmDampness),
        ConstitutionQuestion(text: "您感到嘴里有黏腻的感觉吗？", constitutionType: .phlegmDampness),
        ConstitutionQuestion(text: "您会有痰多（喉咙里总觉得有东西）的情况吗？", constitutionType: .phlegmDampness),

        // 湿热质 (Damp-Heat)
        ConstitutionQuestion(text: "您面部或鼻部有油腻感或油亮发光吗？", constitutionType: .dampHeat),
        ConstitutionQuestion(text: "您容易长痤疮或疮疖吗？", constitutionType: .dampHeat),
        ConstitutionQuestion(text: "您口苦或嘴里有异味吗？", constitutionType: .dampHeat),
        ConstitutionQuestion(text: "您感到大便黏滞不爽（排不尽感）吗？", constitutionType: .dampHeat),
        ConstitutionQuestion(text: "您感到阴部潮湿吗？", constitutionType: .dampHeat),
        ConstitutionQuestion(text: "您会有小便发黄的情况吗？", constitutionType: .dampHeat),

        // 血瘀质 (Blood Stasis)
        ConstitutionQuestion(text: "您皮肤容易出现紫癜（皮下出血）吗？", constitutionType: .bloodStasis),
        ConstitutionQuestion(text: "您两颧部有细微红丝吗？", constitutionType: .bloodStasis),
        ConstitutionQuestion(text: "您身上有不明原因的青紫瘀斑吗？", constitutionType: .bloodStasis),
        ConstitutionQuestion(text: "您感到身体某处疼痛，位置固定吗？", constitutionType: .bloodStasis),
        ConstitutionQuestion(text: "您感到面色晦暗（无光泽）吗？", constitutionType: .bloodStasis),
        ConstitutionQuestion(text: "您的舌头颜色呈紫暗色或有瘀点吗？", constitutionType: .bloodStasis),

        // 气郁质 (Qi Stagnation)
        ConstitutionQuestion(text: "您感到闷闷不乐、情绪低沉吗？", constitutionType: .qiStagnation),
        ConstitutionQuestion(text: "您容易精神紧张、焦虑不安吗？", constitutionType: .qiStagnation),
        ConstitutionQuestion(text: "您容易多愁善感、感情脆弱吗？", constitutionType: .qiStagnation),
        ConstitutionQuestion(text: "您感到胸肋部胀满或疼痛吗？", constitutionType: .qiStagnation),
        ConstitutionQuestion(text: "您感到咽喉部有异物感（吐不出来咽不下去）吗？", constitutionType: .qiStagnation),
        ConstitutionQuestion(text: "您容易无缘无故叹气吗？", constitutionType: .qiStagnation),

        // 特禀质 (Inherited/Allergic)
        ConstitutionQuestion(text: "您没有感冒时也会打喷嚏吗？", constitutionType: .inherited),
        ConstitutionQuestion(text: "您容易对药物、食物、气味过敏吗？", constitutionType: .inherited),
        ConstitutionQuestion(text: "您皮肤容易起荨麻疹吗？", constitutionType: .inherited),
        ConstitutionQuestion(text: "您由于过敏会出现鼻塞、流涕吗？", constitutionType: .inherited),
        ConstitutionQuestion(text: "您的皮肤一抓就红并出现抓痕吗？", constitutionType: .inherited),
        ConstitutionQuestion(text: "您由于过敏会出现咳嗽、喘鸣吗？", constitutionType: .inherited),

        // 平和质 (Balanced)
        ConstitutionQuestion(text: "您精力充沛吗？", constitutionType: .balanced),
        ConstitutionQuestion(text: "您睡眠好吗？", constitutionType: .balanced),
        ConstitutionQuestion(text: "您适应外界自然和社会环境的变化能力强吗？", constitutionType: .balanced),
        ConstitutionQuestion(text: "您比一般人更能适应外界环境的变化吗？", constitutionType: .balanced),
        ConstitutionQuestion(text: "您面色红润有光泽吗？", constitutionType: .balanced),
        ConstitutionQuestion(text: "您说话办事声音洪亮有神吗？", constitutionType: .balanced)
    ]
}

// MARK: - Constitution Recommendation Data
struct ConstitutionRecommendationData {
    static let diet: [ConstitutionType: [String]] = [
        .balanced: ["饮食有节，不偏食", "五谷杂粮均衡搭配", "适量摄入各类食物"],
        .qiDeficiency: ["多吃补气食物如黄芪、党参", "常食山药、红枣", "避免生冷油腻"],
        .yangDeficiency: ["多吃温补食物如羊肉", "常食生姜、桂圆", "避免生冷寒凉"],
        .yinDeficiency: ["多吃滋阴食物如银耳", "常食百合、枸杞", "避免辛辣燥热"],
        .phlegmDampness: ["多吃健脾利湿食物", "常食薏米、冬瓜", "少吃甜腻油腻"],
        .dampHeat: ["多吃清热利湿食物", "常食绿豆、苦瓜", "避免辛辣油腻"],
        .bloodStasis: ["多吃活血食物如山楂", "常食黑木耳、红花", "避免寒凉收涩"],
        .qiStagnation: ["多吃行气解郁食物", "常食玫瑰花、佛手", "避免咖啡浓茶"],
        .inherited: ["避免已知过敏原", "饮食清淡为主", "少吃腥膻发物"]
    ]

    static let exercise: [ConstitutionType: [String]] = [
        .balanced: ["可进行各种运动", "保持适度运动习惯", "注意劳逸结合"],
        .qiDeficiency: ["选择柔和运动如太极", "避免剧烈运动", "循序渐进增加运动量"],
        .yangDeficiency: ["适宜阳光下运动", "可做八段锦", "注意保暖防寒"],
        .yinDeficiency: ["适宜中小强度运动", "避免大汗淋漓", "可做瑜伽冥想"],
        .phlegmDampness: ["坚持有氧运动", "可做快走、游泳", "运动出汗祛湿"],
        .dampHeat: ["适宜大强度运动", "可做游泳、跑步", "运动排汗清热"],
        .bloodStasis: ["适宜各种运动", "促进血液循环", "可做有氧运动"],
        .qiStagnation: ["适宜户外运动", "可做跑步、登山", "培养运动习惯"],
        .inherited: ["避免过敏环境运动", "选择室内运动", "注意运动强度"]
    ]

    static let emotion: [ConstitutionType: [String]] = [
        .balanced: ["保持积极乐观心态", "适时调节情绪", "培养兴趣爱好"],
        .qiDeficiency: ["避免过度劳累", "保持心情舒畅", "充足休息睡眠"],
        .yangDeficiency: ["保持乐观开朗", "多晒太阳", "避免悲观抑郁"],
        .yinDeficiency: ["保持心态平和", "避免情绪激动", "适时放松心情"],
        .phlegmDampness: ["保持积极心态", "避免思虑过度", "培养户外活动"],
        .dampHeat: ["保持心情舒畅", "避免急躁发怒", "适时宣泄情绪"],
        .bloodStasis: ["保持乐观开朗", "避免抑郁寡欢", "适时疏导情绪"],
        .qiStagnation: ["学会情绪管理", "多与人交流", "培养兴趣爱好"],
        .inherited: ["保持心情愉悦", "减少精神压力", "提高免疫力"]
    ]
}

