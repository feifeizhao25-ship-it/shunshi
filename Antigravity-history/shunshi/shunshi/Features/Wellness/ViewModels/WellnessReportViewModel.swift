import Foundation
import SwiftUI

// MARK: - Analysis Structs

/// 睡眠分析
struct SleepAnalysis: Equatable {
    let averageDuration: Double
    let qualityTrend: String  // "improving", "stable", "declining"
    let earlySleepDays: Int
    let consistencyScore: Double  // 0-100
    let issues: [String]
    let bedTimeAverage: String
    let deepSleepPercentage: Double
    
    static let empty = SleepAnalysis(
        averageDuration: 0,
        qualityTrend: "stable",
        earlySleepDays: 0,
        consistencyScore: 0,
        issues: [],
        bedTimeAverage: "--:--",
        deepSleepPercentage: 0
    )
}

/// 营养分析
struct NutritionAnalysis: Equatable {
    let averageCalories: Double
    let proteinAdequacy: Double  // percentage
    let waterAdequacy: Double    // percentage
    let mealRegularity: Double   // 0-100
    let issues: [String]
    let macroBalance: MacroBalance
    let fiberAdequacy: Double
    
    static let empty = NutritionAnalysis(
        averageCalories: 0,
        proteinAdequacy: 0,
        waterAdequacy: 0,
        mealRegularity: 0,
        issues: [],
        macroBalance: MacroBalance(protein: 0, carbs: 0, fat: 0),
        fiberAdequacy: 0
    )
}

struct MacroBalance: Equatable {
    let protein: Double
    let carbs: Double
    let fat: Double
}

/// 情志分析
struct MoodAnalysis: Equatable {
    let averageScore: Double
    let positiveDays: Int
    let stressLevel: String  // "low", "moderate", "high"
    let emotionalStability: Double  // 0-100
    let topEmotions: [String]
    let moodTrend: String  // "improving", "stable", "declining"
    let anxietyDays: Int
    
    static let empty = MoodAnalysis(
        averageScore: 0,
        positiveDays: 0,
        stressLevel: "low",
        emotionalStability: 0,
        topEmotions: [],
        moodTrend: "stable",
        anxietyDays: 0
    )
}

/// 运动分析
struct ExerciseAnalysis: Equatable {
    let totalMinutes: Double
    let activeDays: Int
    let averageIntensity: String  // "light", "moderate", "vigorous"
    let goalAchievement: Double  // percentage
    let traditionalExerciseDays: Int  // 八段锦、太极等
    let caloriesBurned: Double
    let sedentaryDays: Int
    let exerciseVariety: Int  // 运动种类数量
    
    static let empty = ExerciseAnalysis(
        totalMinutes: 0,
        activeDays: 0,
        averageIntensity: "light",
        goalAchievement: 0,
        traditionalExerciseDays: 0,
        caloriesBurned: 0,
        sedentaryDays: 7,
        exerciseVariety: 0
    )
}

/// 综合建议
struct IntegratedSuggestion: Identifiable, Equatable {
    let id = UUID()
    let category: String  // "饮食", "睡眠", "运动", "情志"
    let title: String
    let traditionalAdvice: String
    let modernAdvice: String
    let fusionInsight: String
    let priority: Int  // 1-5
    let icon: String
    let color: Color
}

/// 本周概览
struct WeeklyOverview: Equatable {
    let checkInDays: Int
    let sleepAverage: Double
    let moodStability: Double
    let exerciseDays: Int
    let nutritionScore: Double
    let completionRate: Double
}

// MARK: - Wellness Report ViewModel

@MainActor
final class WellnessReportViewModel: ObservableObject {
    // MARK: - Published Properties - Legacy
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var habitCompletionRate: Double = 0.85
    @Published var totalCheckIns: Int = 24
    @Published var earlySleepDays: Int = 6
    @Published var aiInsight: String = ""
    @Published var isGeneratingImage: Bool = false
    @Published var modernSummary: String = ""
    @Published var modernHighlights: [String] = []
    
    // MARK: - Published Properties - New Weekly Analysis
    @Published var weeklySleepAnalysis: SleepAnalysis = SleepAnalysis.empty
    @Published var weeklyNutritionAnalysis: NutritionAnalysis = NutritionAnalysis.empty
    @Published var weeklyMoodAnalysis: MoodAnalysis = MoodAnalysis.empty
    @Published var weeklyExerciseAnalysis: ExerciseAnalysis = ExerciseAnalysis.empty
    @Published var integratedSuggestions: [IntegratedSuggestion] = []
    @Published var traditionalModernFusionScore: Double = 0.0  // 0-100
    @Published var weeklyOverview: WeeklyOverview = WeeklyOverview(
        checkInDays: 0, sleepAverage: 0, moodStability: 0, exerciseDays: 0, nutritionScore: 0, completionRate: 0
    )
    
    // MARK: - Premium Status
    var isPremium: Bool {
        StoreKitService.shared.subscriptionStatus.isActive
    }
    
    // MARK: - Care Timeline (Premium)
    struct CareTimelineItem: Identifiable {
        let id = UUID()
        let dateResult: String // "今天", "周X"
        let statusTitle: String
        let detail: String
        let status: String // "stable", "needs_attention", "escalate"
    }
    @Published var careTimeline: [CareTimelineItem] = []
    
    // MARK: - Private Properties
    private let modernHealthService = ModernHealthService.shared
    private let calendar = Calendar.current
    
    // MARK: - Public Methods
    
    /// 生成传统报告（兼容旧版本）
    func generateReport(solarTerm: String, constitution: String) {
        // 调用新的综合分析方法
        generateComprehensiveReport(solarTerm: solarTerm, constitution: constitution)
    }
    
    /// 生成综合分析报告 - 结合传统中医与现代健康数据
    func generateComprehensiveReport(solarTerm: String, constitution: String) {
        // 1. 分析各领域数据
        analyzeWeeklySleep()
        analyzeWeeklyNutrition()
        analyzeWeeklyMood()
        analyzeWeeklyExercise()
        
        // 2. 生成本周概览
        generateWeeklyOverview()
        
        // 3. 计算融合评分
        calculateFusionScore(solarTerm: solarTerm, constitution: constitution)
        
        // 4. 生成综合建议
        generateIntegratedSuggestions(solarTerm: solarTerm, constitution: constitution)
        
        // 5. 生成AI洞察
        generateAIInsight(solarTerm: solarTerm, constitution: constitution)
        
        // 6. 更新传统摘要（兼容）
        updateLegacySummary()
        
        // 7. 生成关怀时间轴 (Phase B)
        if isPremium {
            Task {
                await fetchCareHistory()
            }
        }
    }
    
    // MARK: - Care History Fetching
    private func fetchCareHistory() async {
        let userId = AuthService.shared.currentUser?.id ?? "unknown"
        let history = await CareHistoryService.shared.getHistory(userId: userId, from: startDate, to: endDate)
        
        // Map to Timeline Items
        var timeline: [CareTimelineItem] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE" // 周几
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        for event in history.prefix(5) { // Limit to 5 items
            let isToday = calendar.isDateInToday(event.date)
            let dayStr = isToday ? "今天" : dateFormatter.string(from: event.date)
            
            var title = "被安稳照顾中"
            var detail = "状态平稳，继续保持。"
            
            if event.status == "needs_attention" {
                title = "重点关注"
                detail = event.followUpIntent != nil ? "已安排跟进" : "检测到情绪波动"
            } else if event.status == "escalate" {
                title = "需要专业介入"
                detail = "已建议寻求帮助"
            }
            
            if let summary = event.summary {
                detail = summary
            }
            
            timeline.append(CareTimelineItem(
                dateResult: dayStr,
                statusTitle: title,
                detail: detail,
                status: event.status
            ))
        }
        
        // Ensure at least one item if empty (Mock for empty state)
        if timeline.isEmpty {
            timeline.append(CareTimelineItem(
                dateResult: "今天",
                statusTitle: "被安稳照顾中",
                detail: "暂无异常记录，状态良好。",
                status: "stable"
            ))
        }
        
        self.careTimeline = timeline
    }
    
    // MARK: - Weekly Analysis Methods
    
    /// 分析睡眠数据
    private func analyzeWeeklySleep() {
        let sleepTrend = modernHealthService.weeklySleepTrend
        let sleepRecords = modernHealthService.sleepRecords
        let sleepGoal = modernHealthService.sleepGoal
        
        // 计算平均睡眠时长
        let validDurations = sleepTrend.filter { $0.averageDuration > 0 }.map { $0.averageDuration }
        let avgDuration = validDurations.isEmpty ? 0 : validDurations.reduce(0, +) / Double(validDurations.count)
        
        // 计算睡眠质量趋势
        let qualities = sleepTrend.compactMap { $0.averageQuality > 0 ? $0.averageQuality : nil }
        let qualityTrend = calculateTrend(values: qualities)
        
        // 计算早睡天数（22:30前入睡）
        var earlyDays = 0
        var bedtimes: [Date] = []
        var deepSleepMins = 0
        var totalSleepMins = 0
        
        for record in sleepRecords {
            let hour = calendar.component(.hour, from: record.bedtime)
            if hour < 22 || (hour == 22 && calendar.component(.minute, from: record.bedtime) <= 30) {
                earlyDays += 1
            }
            bedtimes.append(record.bedtime)
            deepSleepMins += record.deepSleepMinutes ?? 0
            totalSleepMins += record.totalMinutes
        }
        
        // 计算平均入睡时间
        let avgBedtime = calculateAverageTime(dates: bedtimes)
        
        // 计算一致性分数（标准差的反向）
        let consistency = calculateConsistencyScore(values: validDurations, target: sleepGoal.hoursPerNight)
        
        // 深度睡眠比例
        let deepSleepPct = totalSleepMins > 0 ? Double(deepSleepMins) / Double(totalSleepMins) * 100 : 0
        
        // 识别问题
        var issues: [String] = []
        if avgDuration < 6.5 { issues.append("睡眠不足，平均仅\(String(format: "%.1f", avgDuration))小时") }
        if avgDuration > 9.5 { issues.append("睡眠过长，可能影响阳气生发") }
        if earlyDays < 3 { issues.append("早睡天数较少，建议增加亥时入睡频率") }
        if consistency < 60 { issues.append("睡眠时间不规律，影响生物钟稳定") }
        if deepSleepPct < 15 { issues.append("深度睡眠比例偏低，建议优化睡眠环境") }
        
        weeklySleepAnalysis = SleepAnalysis(
            averageDuration: avgDuration,
            qualityTrend: qualityTrend,
            earlySleepDays: earlyDays,
            consistencyScore: consistency,
            issues: issues,
            bedTimeAverage: avgBedtime,
            deepSleepPercentage: deepSleepPct
        )
    }
    
    /// 分析营养数据
    private func analyzeWeeklyNutrition() {
        let nutritionTrend = modernHealthService.weeklyNutritionTrend
        let nutritionGoals = modernHealthService.nutritionGoals
        let nutritionRecords = modernHealthService.nutritionRecords
        
        // 计算平均卡路里
        let validCalories = nutritionTrend.filter { $0.totalCalories > 0 }.map { $0.totalCalories }
        let avgCalories = validCalories.isEmpty ? 0 : validCalories.reduce(0, +) / Double(validCalories.count)
        
        // 计算蛋白质充足率
        let proteinDays = nutritionTrend.filter { $0.totalProtein >= nutritionGoals.proteinGrams * 0.8 }.count
        let proteinAdequacy = Double(proteinDays) / 7.0 * 100
        
        // 计算饮水充足率
        let waterDays = nutritionTrend.filter { $0.totalWater >= nutritionGoals.waterMl * 0.8 }.count
        let waterAdequacy = Double(waterDays) / 7.0 * 100
        
        // 计算膳食纤维充足率
        let fiberDays = nutritionTrend.filter { $0.totalFiber >= nutritionGoals.fiberGrams * 0.8 }.count
        let fiberAdequacy = Double(fiberDays) / 7.0 * 100
        
        // 计算三餐规律性
        let mealRegularity = calculateMealRegularity(records: nutritionRecords)
        
        // 计算宏量营养素比例
        let totalProtein = nutritionTrend.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = nutritionTrend.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = nutritionTrend.reduce(0) { $0 + $1.totalFat }
        let totalMacros = totalProtein + totalCarbs + totalFat
        
        let macroBalance = MacroBalance(
            protein: totalMacros > 0 ? totalProtein / totalMacros * 100 : 0,
            carbs: totalMacros > 0 ? totalCarbs / totalMacros * 100 : 0,
            fat: totalMacros > 0 ? totalFat / totalMacros * 100 : 0
        )
        
        // 识别问题
        var issues: [String] = []
        if avgCalories < 1200 { issues.append("热量摄入偏低，可能影响气血生化") }
        if avgCalories > 2500 { issues.append("热量摄入偏高，注意脾胃负担") }
        if proteinAdequacy < 50 { issues.append("蛋白质摄入不足，建议增加蛋奶豆类") }
        if waterAdequacy < 50 { issues.append("饮水不足，影响新陈代谢") }
        if fiberAdequacy < 50 { issues.append("膳食纤维不足，可能影响肠道健康") }
        if mealRegularity < 60 { issues.append("用餐时间不规律，建议定时定量") }
        
        weeklyNutritionAnalysis = NutritionAnalysis(
            averageCalories: avgCalories,
            proteinAdequacy: proteinAdequacy,
            waterAdequacy: waterAdequacy,
            mealRegularity: mealRegularity,
            issues: issues,
            macroBalance: macroBalance,
            fiberAdequacy: fiberAdequacy
        )
    }
    
    /// 分析情志数据
    private func analyzeWeeklyMood() {
        let moodTrend = modernHealthService.weeklyMoodTrend
        let moodRecords = modernHealthService.moodRecords
        
        // 计算平均情绪分数
        let validScores = moodTrend.filter { $0.averageScore > 0 }.map { $0.averageScore }
        let avgScore = validScores.isEmpty ? 0 : validScores.reduce(0, +) / Double(validScores.count)
        
        // 计算积极天数
        let positiveDays = moodTrend.filter { $0.averageScore >= 7 }.count
        
        // 计算压力水平
        let stressLevels = moodRecords.compactMap { $0.stressLevel }
        let avgStress = stressLevels.isEmpty ? 0 : Double(stressLevels.reduce(0, +)) / Double(stressLevels.count)
        let stressLevel: String
        if avgStress <= 4 { stressLevel = "low" }
        else if avgStress <= 7 { stressLevel = "moderate" }
        else { stressLevel = "high" }
        
        // 计算情绪稳定性（标准差的反向）
        let stability = calculateEmotionalStability(scores: validScores)
        
        // 统计主要情绪
        var emotionCounts: [String: Int] = [:]
        for record in moodRecords {
            for emotion in record.emotions {
                emotionCounts[emotion.rawValue, default: 0] += 1
            }
        }
        let topEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        // 计算情绪趋势
        let moodTrendStr = calculateTrend(values: validScores)
        
        // 计算焦虑天数
        let anxietyDays = moodRecords.filter { 
            $0.emotions.contains(.anxious) || $0.emotions.contains(.stressed) 
        }.count
        
        weeklyMoodAnalysis = MoodAnalysis(
            averageScore: avgScore,
            positiveDays: positiveDays,
            stressLevel: stressLevel,
            emotionalStability: stability,
            topEmotions: topEmotions,
            moodTrend: moodTrendStr,
            anxietyDays: anxietyDays
        )
    }
    
    /// 分析运动数据
    private func analyzeWeeklyExercise() {
        let exerciseTrend = modernHealthService.weeklyExerciseTrend
        let exerciseRecords = modernHealthService.exerciseRecords
        _ = modernHealthService.exerciseGoal
        
        // 计算总运动时长
        let totalMinutes = exerciseTrend.reduce(0) { $0 + $1.totalMinutes }
        
        // 计算活跃天数
        let activeDays = exerciseTrend.filter { $0.totalMinutes > 0 }.count
        
        // 计算平均强度
        let caloriesPerMinute = totalMinutes > 0 ? exerciseTrend.reduce(0) { $0 + $1.totalCalories } / totalMinutes : 0
        let intensity: String
        if caloriesPerMinute < 4 { intensity = "light" }
        else if caloriesPerMinute < 8 { intensity = "moderate" }
        else { intensity = "vigorous" }
        
        // 计算目标达成率
        let goalAchievement = min(Double(activeDays) / 7.0 * 100, 100)
        
        // 计算传统运动天数
        let traditionalDays = Set(exerciseRecords.filter { $0.isTraditional }.map { 
            calendar.startOfDay(for: $0.date) 
        }).count
        
        // 计算消耗卡路里
        let caloriesBurned = exerciseTrend.reduce(0) { $0 + $1.totalCalories }
        
        // 计算久坐天数（无运动记录）
        let sedentaryDays = 7 - activeDays
        
        // 计算运动多样性
        let exerciseTypes = Set(exerciseRecords.map { $0.exerciseType })
        let variety = exerciseTypes.count
        
        weeklyExerciseAnalysis = ExerciseAnalysis(
            totalMinutes: totalMinutes,
            activeDays: activeDays,
            averageIntensity: intensity,
            goalAchievement: goalAchievement,
            traditionalExerciseDays: traditionalDays,
            caloriesBurned: caloriesBurned,
            sedentaryDays: sedentaryDays,
            exerciseVariety: variety
        )
    }
    
    // MARK: - Helper Methods
    
    /// 计算趋势
    private func calculateTrend(values: [Double]) -> String {
        guard values.count >= 3 else { return "stable" }
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg * 1.05 { return "improving" }
        if secondAvg < firstAvg * 0.95 { return "declining" }
        return "stable"
    }
    
    /// 计算平均时间
    private func calculateAverageTime(dates: [Date]) -> String {
        guard !dates.isEmpty else { return "--:--" }
        var totalMinutes = 0
        for date in dates {
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            totalMinutes += hour * 60 + minute
        }
        let avgMinutes = totalMinutes / dates.count
        let avgHour = avgMinutes / 60
        let avgMin = avgMinutes % 60
        return String(format: "%02d:%02d", avgHour, avgMin)
    }
    
    /// 计算一致性分数
    private func calculateConsistencyScore(values: [Double], target: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let stdDev = sqrt(variance)
        // 标准差越小，一致性越高
        let consistency = max(0, 100 - stdDev * 20)
        return min(consistency, 100)
    }
    
    /// 计算情绪稳定性
    private func calculateEmotionalStability(scores: [Double]) -> Double {
        guard scores.count >= 2 else { return 50 }
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.reduce(0) { $0 + pow($1 - mean, 2) } / Double(scores.count)
        let stdDev = sqrt(variance)
        // 标准差越小越稳定
        return max(0, 100 - stdDev * 15)
    }
    
    /// 计算三餐规律性
    private func calculateMealRegularity(records: [ModernNutritionRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        var mealTimes: [Int: [Int]] = [:] // hour -> [count by day]
        
        for record in records {
            let hour = calendar.component(.hour, from: record.date)
            let day = calendar.component(.day, from: record.date)
            mealTimes[hour, default: []].append(day)
        }
        
        // 简单规律性评分：看是否有固定用餐时间
        var regularityScore = 0.0
        for (_, days) in mealTimes {
            if days.count >= 3 { regularityScore += 25 } // 某时段有3天以上记录
        }
        return min(regularityScore, 100)
    }
    
    // MARK: - Report Generation Methods
    
    /// 生成本周概览
    private func generateWeeklyOverview() {
        let checkInDays = modernHealthService.weeklySleepTrend.filter { $0.totalDays > 0 }.count
        let sleepAvg = weeklySleepAnalysis.averageDuration
        let moodStability = weeklyMoodAnalysis.emotionalStability
        let exerciseDays = weeklyExerciseAnalysis.activeDays
        let nutritionScore = (weeklyNutritionAnalysis.proteinAdequacy + weeklyNutritionAnalysis.waterAdequacy) / 2
        let completionRate = Double(checkInDays) / 7.0
        
        weeklyOverview = WeeklyOverview(
            checkInDays: checkInDays,
            sleepAverage: sleepAvg,
            moodStability: moodStability,
            exerciseDays: exerciseDays,
            nutritionScore: nutritionScore,
            completionRate: completionRate
        )
    }
    
    /// 计算融合评分
    private func calculateFusionScore(solarTerm: String, constitution: String) {
        // 1. 传统合规性评分 (25%)
        let traditionalScore = calculateTraditionalCompliance(solarTerm: solarTerm)
        
        // 2. 现代指标评分 (25%)
        let modernScore = calculateModernMetricsScore()
        
        // 3. 平衡评分 (25%)
        let balanceScore = calculateBalanceScore()
        
        // 4. 一致性评分 (25%)
        let consistencyScore = weeklySleepAnalysis.consistencyScore
        
        // 加权计算
        let fusionScore = (traditionalScore * 0.25) + (modernScore * 0.25) + (balanceScore * 0.25) + (consistencyScore * 0.25)
        traditionalModernFusionScore = min(max(fusionScore, 0), 100)
    }
    
    /// 计算传统合规性
    private func calculateTraditionalCompliance(solarTerm: String) -> Double {
        var score = 70.0 // 基础分
        
        // 早睡加分
        score += Double(weeklySleepAnalysis.earlySleepDays) * 3
        
        // 传统运动加分
        score += Double(weeklyExerciseAnalysis.traditionalExerciseDays) * 4
        
        // 情绪稳定加分
        if weeklyMoodAnalysis.stressLevel == "low" { score += 10 }
        
        return min(score, 100)
    }
    
    /// 计算现代指标评分
    private func calculateModernMetricsScore() -> Double {
        var scores: [Double] = []
        
        // 睡眠评分
        let sleepScore = min(weeklySleepAnalysis.averageDuration / 8 * 100, 100)
        scores.append(sleepScore)
        
        // 营养评分
        let nutritionScore = (weeklyNutritionAnalysis.proteinAdequacy + weeklyNutritionAnalysis.waterAdequacy) / 2
        scores.append(nutritionScore)
        
        // 运动评分
        let exerciseScore = weeklyExerciseAnalysis.goalAchievement
        scores.append(exerciseScore)
        
        // 情绪评分
        let moodScore = weeklyMoodAnalysis.averageScore * 10
        scores.append(moodScore)
        
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    /// 计算平衡评分
    private func calculateBalanceScore() -> Double {
        var score = 70.0
        
        // 工作-生活平衡（通过运动天数间接反映）
        score += Double(weeklyExerciseAnalysis.activeDays) * 3
        
        // 压力管理
        if weeklyMoodAnalysis.stressLevel == "low" { score += 15 }
        else if weeklyMoodAnalysis.stressLevel == "moderate" { score += 5 }
        
        return min(score, 100)
    }
    
    /// 生成综合建议
    private func generateIntegratedSuggestions(solarTerm: String, constitution: String) {
        var suggestions: [IntegratedSuggestion] = []
        
        // 睡眠建议
        if weeklySleepAnalysis.averageDuration < 7 || weeklySleepAnalysis.earlySleepDays < 3 {
            suggestions.append(IntegratedSuggestion(
                category: "睡眠",
                title: "亥时入睡结合睡眠监测",
                traditionalAdvice: "\(solarTerm)时节宜亥时(21-23点)入睡，养藏阳气，\(constitution)者更需注意早睡养气血",
                modernAdvice: "本周平均入睡\(weeklySleepAnalysis.bedTimeAverage)，睡眠\(String(format: "%.1f", weeklySleepAnalysis.averageDuration))小时，建议提前30分钟入睡",
                fusionInsight: "传统亥时入眠与现代睡眠科学高度契合，此时段入睡可最大化深度睡眠比例（当前\(String(format: "%.1f", weeklySleepAnalysis.deepSleepPercentage))%）",
                priority: 5,
                icon: "moon.stars.fill",
                color: .indigo
            ))
        }
        
        // 饮食建议
        if weeklyNutritionAnalysis.proteinAdequacy < 60 || weeklyNutritionAnalysis.waterAdequacy < 60 {
            let isWinter = solarTerm.contains("冬") || solarTerm.contains("雪") || solarTerm.contains("寒")
            suggestions.append(IntegratedSuggestion(
                category: "饮食",
                title: "\(solarTerm)食养结合营养补充",
                traditionalAdvice: isWinter ? "\(solarTerm)宜温补，\(constitution)者可多食羊肉、黑豆等温阳食材" : "\(solarTerm)时节宜顺应天时，选择当季新鲜食材",
                modernAdvice: "蛋白质充足率\(String(format: "%.0f", weeklyNutritionAnalysis.proteinAdequacy))%，建议每日增加20g优质蛋白；饮水达标率\(String(format: "%.0f", weeklyNutritionAnalysis.waterAdequacy))%",
                fusionInsight: "传统食补智慧与现代营养学相通，如黑色食物（黑豆、黑芝麻）既符合中医'黑色入肾'理论，又富含植物蛋白和微量元素",
                priority: 4,
                icon: "leaf.fill",
                color: .green
            ))
        }
        
        // 运动建议
        if weeklyExerciseAnalysis.activeDays < 3 {
            suggestions.append(IntegratedSuggestion(
                category: "运动",
                title: "动静结合改善久坐状态",
                traditionalAdvice: "\(constitution)者宜选择八段锦、太极拳等柔和运动，顺应\(solarTerm)节气特点",
                modernAdvice: "本周仅运动\(weeklyExerciseAnalysis.activeDays)天，建议每周至少150分钟中等强度运动",
                fusionInsight: "传统养生功法如八段锦，动作柔和但能有效激活核心肌群，现代研究证实其可改善心肺功能和平衡能力",
                priority: 4,
                icon: "figure.mind.and.body",
                color: .orange
            ))
        }
        
        // 情绪建议
        if weeklyMoodAnalysis.stressLevel == "high" || weeklyMoodAnalysis.anxietyDays >= 3 {
            suggestions.append(IntegratedSuggestion(
                category: "情志",
                title: "情志调和与压力管理",
                traditionalAdvice: "\(solarTerm)时节\(constitution)者宜保持心境平和，可通过静坐、冥想调养心神",
                modernAdvice: "本周检测到\(weeklyMoodAnalysis.anxietyDays)天压力/焦虑情绪，建议每日安排15分钟放松时段",
                fusionInsight: "中医'情志致病'理论与现代心身医学相呼应，冥想、呼吸练习既能'调神'又能降低皮质醇水平",
                priority: 5,
                icon: "heart.fill",
                color: .pink
            ))
        }
        
        // 传统运动建议（如缺乏传统运动）
        if weeklyExerciseAnalysis.traditionalExerciseDays == 0 && weeklyExerciseAnalysis.activeDays > 0 {
            suggestions.append(IntegratedSuggestion(
                category: "运动",
                title: "融入传统养生功法",
                traditionalAdvice: "\(constitution)者练习八段锦可调和气血，特别适合\(solarTerm)时节",
                modernAdvice: "当前运动以现代方式为主，建议每周增加2次传统养生功法",
                fusionInsight: "八段锦等功法已被现代医学研究证实可改善柔韧性、平衡能力和心理健康，是优秀的交叉训练选择",
                priority: 3,
                icon: "figure.tai.chi",
                color: .purple
            ))
        }
        
        // 规律性建议
        if weeklySleepAnalysis.consistencyScore < 60 || weeklyNutritionAnalysis.mealRegularity < 60 {
            suggestions.append(IntegratedSuggestion(
                category: "起居",
                title: "建立规律作息节律",
                traditionalAdvice: "《黄帝内经》强调'起居有常'，\(constitution)者更需规律以养正气",
                modernAdvice: "睡眠规律性\(String(format: "%.0f", weeklySleepAnalysis.consistencyScore))%，用餐规律性\(String(format: "%.0f", weeklyNutritionAnalysis.mealRegularity))%，建议设定固定作息时间表",
                fusionInsight: "生物钟节律是中医'天人相应'理论的现代诠释，规律作息可优化激素分泌和代谢效率",
                priority: 4,
                icon: "clock.fill",
                color: .blue
            ))
        }
        
        // 按优先级排序
        integratedSuggestions = suggestions.sorted { $0.priority > $1.priority }
    }
    
    /// 生成AI洞察
    private func generateAIInsight(solarTerm: String, constitution: String) {
        var insights: [String] = []
        
        // 开场
        insights.append("本周您的融合健康评分为\(String(format: "%.0f", traditionalModernFusionScore))分。")
        
        // 睡眠洞察
        if weeklySleepAnalysis.earlySleepDays >= 5 {
            insights.append("在\(solarTerm)时节，您很好地践行了'早卧晚起'的起居原则，早睡达标\(weeklySleepAnalysis.earlySleepDays)天。")
        } else if weeklySleepAnalysis.earlySleepDays < 3 {
            insights.append("\(solarTerm)时节宜'早卧晚起'以养藏阳气，建议增加亥时(21-23点)前入睡的频率。")
        }
        
        // 体质相关洞察
        insights.append("结合您的\(constitution)特点，")
        
        if constitution.contains("气虚") {
            if weeklyExerciseAnalysis.traditionalExerciseDays > 0 {
                insights.append("练习八段锦等柔和运动有助于补益肺气，您的坚持值得肯定。")
            } else {
                insights.append("建议增加八段锦等柔和运动，避免剧烈运动耗气。")
            }
        } else if constitution.contains("阳虚") {
            if weeklyNutritionAnalysis.averageCalories > 1500 {
                insights.append("适当的温补饮食有助于改善阳虚体质，注意避免生冷食物。")
            }
        }
        
        // 现代数据洞察
        if weeklyMoodAnalysis.stressLevel == "high" {
            insights.append("现代健康数据显示您本周压力水平较高，建议结合冥想或呼吸练习进行调节。")
        }
        
        // 综合建议
        if !integratedSuggestions.isEmpty {
            let topSuggestion = integratedSuggestions[0]
            insights.append("优先建议：\(topSuggestion.title)——\(topSuggestion.fusionInsight)")
        }
        
        aiInsight = insights.joined(separator: "")
    }
    
    /// 更新传统摘要（兼容旧版本）
    private func updateLegacySummary() {
        modernSummary = "现代指标显示：睡眠均值\(String(format: "%.1f", weeklySleepAnalysis.averageDuration))小时，热量摄入\(Int(weeklyNutritionAnalysis.averageCalories))kcal，情绪评分\(String(format: "%.1f", weeklyMoodAnalysis.averageScore))分，运动\(Int(weeklyExerciseAnalysis.totalMinutes))分钟。融合评分\(String(format: "%.0f", traditionalModernFusionScore))分。"
        
        var highlights: [String] = []
        if weeklySleepAnalysis.averageDuration < 6.5 { highlights.append("睡眠略不足，建议本周增加30-45分钟睡眠") }
        if weeklyNutritionAnalysis.averageCalories < 1200 { highlights.append("热量偏低，建议补充优质蛋白与主食") }
        if weeklyMoodAnalysis.averageScore < 6.5 { highlights.append("情绪波动偏大，建议安排固定放松时段") }
        if weeklyExerciseAnalysis.activeDays < 3 { highlights.append("运动量偏少，建议累计150分钟轻中等运动") }
        if highlights.isEmpty {
            highlights.append("现代指标整体稳定，继续保持良好作息与运动习惯")
        }
        modernHighlights = highlights
        
        // 更新传统属性
        habitCompletionRate = weeklyOverview.completionRate
        totalCheckIns = weeklyOverview.checkInDays * 4  // 估算
        earlySleepDays = weeklySleepAnalysis.earlySleepDays
    }
}

