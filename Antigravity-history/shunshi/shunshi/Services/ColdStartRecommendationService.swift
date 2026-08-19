import Foundation
import Combine

// MARK: - Cold Start Recommendation Service
/// 新用户冷启动推荐服务 - 基于用户画像、体质、节气的个性化推荐
final class ColdStartRecommendationService {
    static let shared = ColdStartRecommendationService()
    
    private let contentService: ContentService
    private let userService: UserService
    
    private init() {
        self.contentService = ContentService.shared
        self.userService = UserService.shared
    }
    
    // MARK: - 冷启动推荐入口
    /// 为新用户生成个性化推荐
    func generateRecommendations(for user: ColdStartUser) -> AnyPublisher<[ColdStartContentItem], Never> {
        // 根据用户状态选择推荐策略
        if let constitution = user.constitution {
            // 优先级1：有体质数据
            return recommendByConstitution(constitution)
                .map { $0 + self.getSolarTermContent() }
                .eraseToAnyPublisher()
        }
        
        if !user.concerns.isEmpty {
            // 优先级2：有关注问题
            return recommendByConcerns(user.concerns)
                .map { $0 + self.getSolarTermContent() }
                .eraseToAnyPublisher()
        }
        
        // 优先级3：基于人群统计
        return recommendByCollaborativeFiltering(age: user.age, gender: user.gender, city: user.city)
            .map { $0 + self.getHotContent() + self.getSolarTermContent() }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 基于体质推荐
    private func recommendByConstitution(_ constitution: ColdStartConstitution) -> AnyPublisher<[ColdStartContentItem], Never> {
        let solarTerm = ColdStartSolarTerm.current
        
        return contentService.queryContents()
            .map { contents in
                contents
                    .filter { content in
                        // 匹配体质
                        content.suitableConstitutions.contains(constitution.id)
                    }
                    // 按节气排序
                    .sorted { item1, item2 in
                        let term1Match = item1.solarTerms.contains(solarTerm.name) ? 1 : 0
                        let term2Match = item2.solarTerms.contains(solarTerm.name) ? 1 : 0
                        return term1Match > term2Match
                    }
                    .prefix(10)
                    .map { $0 }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 基于关注问题推荐
    private func recommendByConcerns(_ concerns: [String]) -> AnyPublisher<[ColdStartContentItem], Never> {
        contentService.queryContents()
            .map { contents in
                contents
                    .filter { content in
                        concerns.contains { concern in
                            content.tags.contains(concern)
                        }
                    }
                    .sortedByPopularity()
                    .prefix(10)
                    .map { $0 }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 基于协同过滤推荐
    private func recommendByCollaborativeFiltering(age: Int?, gender: String?, city: String?) -> AnyPublisher<[ColdStartContentItem], Never> {
        // 查找相似用户
        return userService.findSimilarUsers(age: age, gender: gender, city: city)
            .map { similarUsers in
                // 统计相似用户喜欢的内容
                let likedContentIds = similarUsers
                    .flatMap { $0.likedContents }
                    .countByValue()
                    .sorted { $0.value > $1.value }
                    .prefix(10)
                    .map { $0.key }
                
                return likedContentIds
            }
            .flatMap { [weak self] (contentIds: [String]) -> AnyPublisher<[ColdStartContentItem], Never> in
                guard let self = self else {
                    return Just([]).eraseToAnyPublisher()
                }
                return self.contentService.queryContents()
                    .map { contents in
                        contents
                            .filter { contentIds.contains($0.id) }
                            .prefix(10)
                            .map { $0 }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 获取节气内容
    private func getSolarTermContent() -> [ColdStartContentItem] {
        let solarTerm = ColdStartSolarTerm.current
        return ContentService.shared.mockContents
            .filter { $0.solarTerms.contains(solarTerm.name) }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - 获取热门内容
    private func getHotContent() -> [ColdStartContentItem] {
        return ContentService.shared.mockContents
            .sortedByPopularity()
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - AI对话冷启动策略
    /// 生成首次对话的引导语
    func generateColdStartGreeting(for user: ColdStartUser) -> String {
        let solarTerm = ColdStartSolarTerm.current
        let solarTermEmoji = solarTerm.emoji
        
        if let name = user.nickname {
            return """
            你好呀，\(name)！我是小顺，很高兴认识你~🌿
            
            现在是\(solarTermEmoji)\(solarTerm.name)时节，很适合聊聊养生话题呢。
            
            我可以陪你聊聊：
            • 节气养生小贴士
            • 体质调理建议
            • 食疗和茶饮
            • 穴位保健方法
            • 日常健康习惯
            
            有什么想聊的吗？或者告诉我你的昵称，我就可以开始啦~
            """
        }
        
        return """
        你好呀！我是小顺，很高兴认识你~🌿
        
        我是一个懂养生的AI朋友，可以陪你聊聊节气养生、体质调理、食疗茶饮这些话题。
        
        方便告诉我怎么称呼你吗？
        """
    }
    
    /// 生成前5次对话的信息采集提示
    func generateInfoCollectionPrompt(currentInfoCount: Int, user: User) -> String? {
        // 采集优先级
        let collectionList = [
            ("称呼偏好", "我该怎么称呼你比较好呀？"),
            ("作息时间", "你一般几点睡觉呀？"),
            ("饮食偏好", "平时口味偏清淡还是重口？"),
            ("运动习惯", "有运动的习惯吗？"),
            ("主要困扰", "最近有什么想调理的吗？")
        ]
        
        // 检查已采集的信息
        var collectedInfo: Set<String> = []
        if user.nickname != nil { collectedInfo.insert("称呼偏好") }
        if user.sleepHabit != nil { collectedInfo.insert("作息时间") }
        if user.foodPreference != nil { collectedInfo.insert("饮食偏好") }
        if user.exerciseHabit != nil { collectedInfo.insert("运动习惯") }
        if user.concerns.isEmpty == false { collectedInfo.insert("主要困扰") }
        
        // 选择下一个要采集的信息
        for (info, prompt) in collectionList {
            if !collectedInfo.contains(info) && currentInfoCount < 3 {
                // 随机选择，30%的概率采集
                if Int.random(in: 0..<10) < 3 {
                    return prompt
                }
            }
        }
        
        return nil
    }
}

// MARK: - Content Service (简化的内容服务)
final class ContentService {
    static let shared = ContentService()
    
    private init() {}
    
    func queryContents() -> AnyPublisher<[ColdStartContentItem], Never> {
        // TODO: 从后端API获取
        Just(mockContents).eraseToAnyPublisher()
    }
    
    var mockContents: [ColdStartContentItem] {
        [
            ColdStartContentItem(id: "1", title: "小雪养生指南", type: ColdStartContentItem.ColdStartContentType.solarTerm, tags: ["小雪", "冬季", "养生"], solarTerms: ["小雪"]),
            ColdStartContentItem(id: "2", title: "气虚质调理方案", type: ColdStartContentItem.ColdStartContentType.constitution, tags: ["气虚", "体质", "调理"], solarTerms: []),
            ColdStartContentItem(id: "3", title: "红枣枸杞茶", type: ColdStartContentItem.ColdStartContentType.tea, tags: ["红枣", "枸杞", "茶饮"], solarTerms: ["小雪", "冬季"]),
            ColdStartContentItem(id: "4", title: "足三里穴位", type: ColdStartContentItem.ColdStartContentType.acupoint, tags: ["足三里", "穴位", "调理"], solarTerms: []),
            ColdStartContentItem(id: "5", title: "八段锦教程", type: ColdStartContentItem.ColdStartContentType.exercise, tags: ["八段锦", "运动", "养生"], solarTerms: [])
        ]
    }
}

// MARK: - User Service (简化的用户服务)
final class UserService {
    static let shared = UserService()
    
    private init() {}
    
    func findSimilarUsers(age: Int?, gender: String?, city: String?) -> AnyPublisher<[User], Never> {
        // TODO: 从后端API获取相似用户
        Just([]).eraseToAnyPublisher()
    }
}

// MARK: - 服务层专用用户类型
struct ColdStartUser {
    let id: String
    var nickname: String?
    var age: Int?
    var gender: String?
    var city: String?
    var constitution: ColdStartConstitution?
    var concerns: [String]
    var foodTaboos: [String]
    var sleepHabit: String?
    var foodPreference: String?
    var exerciseHabit: String?
    var likedContents: [String]

    init(id: String) {
        self.id = id
        self.concerns = []
        self.foodTaboos = []
        self.likedContents = []
    }
}

struct ColdStartConstitution {
    let id: String
    let name: String
    let description: String
}

struct ColdStartSolarTerm {
    let name: String
    let day: Int
    let emoji: String

    static var current: ColdStartSolarTerm {
        ColdStartSolarTerm(name: "小雪", day: 15, emoji: "❄️")
    }
}

// MARK: - Content Item (服务层专用)
struct ColdStartContentItem: Identifiable {
    let id: String
    let title: String
    let type: ColdStartContentType
    let tags: [String]
    let solarTerms: [String]

    var suitableConstitutions: [String] {
        return []
    }

    enum ColdStartContentType {
        case solarTerm
        case constitution
        case tea
        case acupoint
        case exercise
        case recipe
        case article
    }
}

// MARK: - Array Extension
extension Array where Element == String {
    func countByValue() -> [(key: String, value: Int)] {
        var counts: [String: Int] = [:]
        for item in self {
            counts[item, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }
}

extension Array where Element: Identifiable {
    func sortedByPopularity() -> [Element] {
        self
    }
}
