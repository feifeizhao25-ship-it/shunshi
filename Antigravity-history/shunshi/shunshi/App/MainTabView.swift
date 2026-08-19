import SwiftUI

// MARK: - Tab Type (5个Tab设计)
enum AppTab: String, CaseIterable, Identifiable {
    case home = "home"
    case wellness = "wellness"
    case consultant = "consultant"
    case journal = "journal"
    case profile = "profile"
    
    var id: String { rawValue }
    
    /// 标题 - 按照设计方案
    var title: String {
        switch self {
        case .home: return "首页"
        case .wellness: return "养生"
        case .consultant: return "咨询"
        case .journal: return "记录"
        case .profile: return "我的"
        }
    }
    
    /// 未选中图标
    var icon: String {
        switch self {
        case .home: return "house"
        case .wellness: return "leaf"
        case .consultant: return "bubble.left.and.bubble.right"
        case .journal: return "book"
        case .profile: return "person"
        }
    }
    
    /// 选中图标
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .wellness: return "leaf.fill"
        case .consultant: return "bubble.left.and.bubble.right.fill"
        case .journal: return "book.fill"
        case .profile: return "person.fill"
        }
    }
    
    /// 选中时的强调色
    var accentColor: Color {
        SeasonalColors.currentSeasonPrimary
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject private var appStateService: AppStateService
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(AppTab.home)
                
                WellnessView()
                    .tag(AppTab.wellness)
                
                ConsultantView()
                    .tag(AppTab.consultant)
                
                JournalView()
                    .tag(AppTab.journal)
                
                ProfileView()
                    .tag(AppTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            ShunshiTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Custom Tab Bar (顺时风格)
struct ShunshiTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部细分割线
            Rectangle()
                .fill(AppBackground.divider)
                .frame(height: 0.5)
            
            // TabBar背景
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    ShunshiTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.small)
            .padding(.bottom, Spacing.safeAreaBottom + 8)
            .background(
                AppBackground.card
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
            )
        }
        .background(AppBackground.primary)
    }
}

// MARK: - Tab Button
struct ShunshiTabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 图标
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? tab.accentColor : AppText.tertiary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                // 标题
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? tab.accentColor : AppText.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Journal View (记录页 - 数据记录与分析)
struct JournalView: View {
    @StateObject private var recordService = WellnessRecordService.shared
    @State private var showQuickRecord = false
    @State private var selectedAnalysisType: AnalysisType = .weekly
    
    enum AnalysisType: String, CaseIterable {
        case weekly = "周分析"
        case monthly = "月分析"
        case trends = "趋势"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 养生指数卡片
                    JournalWellnessScoreCard(recordService: recordService)
                    
                    // 快速记录入口
                    QuickRecordSection(showQuickRecord: $showQuickRecord)
                    
                    // 记录分析切换
                    Picker("分析类型", selection: $selectedAnalysisType) {
                        ForEach(AnalysisType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 根据选择显示不同分析
                    switch selectedAnalysisType {
                    case .weekly:
                        WeeklyAnalysisCard(recordService: recordService)
                    case .monthly:
                        MonthlyAnalysisCard(recordService: recordService)
                    case .trends:
                        TrendsAnalysisCard(recordService: recordService)
                    }
                    
                    // 详细记录列表
                    DetailedRecordsSection(recordService: recordService)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showQuickRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showQuickRecord) {
                JournalQuickRecordSheet(recordService: recordService)
            }
        }
    }
}

// MARK: - Quick Record Section
struct QuickRecordSection: View {
    @Binding var showQuickRecord: Bool
    
    var body: some View {
        Button(action: { showQuickRecord = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("快速记录")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("记录饮食、运动、睡眠、情绪")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Journal Wellness Score Card
struct JournalWellnessScoreCard: View {
    @ObservedObject var recordService: WellnessRecordService
    
    private var score: Int {
        recordService.calculateOverallScore()
    }
    
    private var scoreDescription: String {
        if score == 0 && recordService.dietRecords.isEmpty && recordService.exerciseRecords.isEmpty {
            return "准备好开启第一步了吗？"
        }
        switch score {
        case 0...40: return "养生之旅刚刚起步"
        case 41...60: return "正在养成良好习惯"
        case 61...80: return "身体状态稳步提升"
        case 81...90: return "养生习惯非常出色"
        default: return "真正的养生达人！"
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0...40: return .red
        case 41...60: return .orange
        case 61...80: return .yellow
        case 81...90: return .green
        default: return .purple
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("养生指数")
                        .font(.headline)
                    Text(scoreDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(score)")
                        .font(.title3.bold())
                        .foregroundColor(scoreColor)
                }
            }
            
            // 五维度进度条
            HStack(spacing: 4) {
                ForEach(WuWeiType.allCases) { type in
                    JournalMiniBar(type: type, score: dimensionScore(type))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func dimensionScore(_ type: WuWeiType) -> Int {
        switch type {
        case .diet:
            let count = recordService.dietRecords.count
            return min(count * 10, 100)
        case .exercise:
            let minutes = recordService.exerciseRecords.reduce(0) { $0 + $1.duration }
            return min(minutes / 3, 100)
        case .living:
            let avgQuality = recordService.sleepRecords.isEmpty ? 0 : 
                recordService.sleepRecords.reduce(0) { $0 + $1.quality } / recordService.sleepRecords.count
            return avgQuality
        case .emotion:
            let happyCount = recordService.moodRecords.filter {
                $0.mood == .happy || $0.mood == .veryHappy
            }.count
            let total = recordService.moodRecords.count
            return total > 0 ? (happyCount * 100 / total) : 0
        case .acupoint:
            let count = recordService.habitCheckIns.filter { $0.habitId == "acupoint_massage" && $0.completed }.count
            return min(count * 20, 100)
        }
    }
}

// MARK: - Journal Mini Bar
struct JournalMiniBar: View {
    let type: WuWeiType
    let score: Int
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                    .frame(width: geometry.size.width, height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(type.color)
                    .frame(width: geometry.size.width * CGFloat(score) / 100, height: 4)
            }
            .frame(height: 4)
            Image(systemName: type.icon)
                .font(.system(size: 8))
                .foregroundColor(type.color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Journal Quick Record Sheet
struct JournalQuickRecordSheet: View {
    @ObservedObject var recordService: WellnessRecordService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0
    @State private var mealType: DietRecord.MealType = .breakfast
    @State private var foodName: String = ""
    @State private var calories: Int = 300
    @State private var exerciseType: String = ""
    @State private var exerciseDuration: Int = 30
    @State private var sleepQuality: Int = 80
    @State private var moodType: MoodRecord.MoodType = .happy
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型选择
                Picker("记录类型", selection: $selectedTab) {
                    Text("饮食").tag(0)
                    Text("运动").tag(1)
                    Text("睡眠").tag(2)
                    Text("情绪").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0:
                            dietRecordForm
                        case 1:
                            exerciseRecordForm
                        case 2:
                            sleepRecordForm
                        case 3:
                            moodRecordForm
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("快速记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var dietRecordForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach([DietRecord.MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { type in
                    Button(type.rawValue.capitalized) {
                        mealType = type
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(mealType == type ? Color.orange : Color(.systemGray5))
                    .foregroundColor(mealType == type ? .white : .primary)
                    .cornerRadius(8)
                }
            }
            
            TextField("食物名称", text: $foodName)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading) {
                Text("热量: \(calories) 千卡")
                Slider(value: Binding(get: { Double(calories) }, set: { calories = Int($0) }), in: 0...1500, step: 50)
                    .tint(.orange)
            }
        }
    }
    
    private var exerciseRecordForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("运动类型", text: $exerciseType)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading) {
                Text("时长: \(exerciseDuration) 分钟")
                Slider(value: Binding(get: { Double(exerciseDuration) }, set: { exerciseDuration = Int($0) }), in: 5...180, step: 5)
                    .tint(.green)
            }
        }
    }
    
    private var sleepRecordForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("睡眠质量: \(sleepQuality)%")
                Slider(value: Binding(get: { Double(sleepQuality) }, set: { sleepQuality = Int($0) }), in: 0...100, step: 5)
                    .tint(.indigo)
                
                HStack {
                    Text("差").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("优").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var moodRecordForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今天的心情")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(MoodRecord.MoodType.allCases, id: \.self) { mood in
                    Button {
                        moodType = mood
                    } label: {
                        VStack {
                            Text(mood.emoji)
                                .font(.system(size: 28))
                            Text(mood.displayName)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(moodType == mood ? moodColor(mood).opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(moodType == mood ? moodColor(mood) : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func moodColor(_ mood: MoodRecord.MoodType) -> Color {
        switch mood {
        case .veryHappy: return .yellow
        case .happy: return .green
        case .neutral: return .gray
        case .sad: return .blue
        case .verySad: return .purple
        }
    }
    
    private func saveRecord() {
        switch selectedTab {
        case 0:
            let record = DietRecord(id: UUID().uuidString, date: Date(), mealType: mealType, food: foodName, calories: calories, notes: nil)
            recordService.addDietRecord(record)
        case 1:
            let record = ExerciseRecord(id: UUID().uuidString, date: Date(), type: exerciseType, duration: exerciseDuration, calories: exerciseDuration * 5)
            recordService.addExerciseRecord(record)
        case 2:
            let record = SleepRecord(id: UUID().uuidString, date: Date(), bedtime: nil, wakeTime: nil, duration: 7.5, quality: sleepQuality)
            recordService.addSleepRecord(record)
        case 3:
            let record = MoodRecord(id: UUID().uuidString, date: Date(), mood: moodType, note: nil)
            recordService.addMoodRecord(record)
        default:
            break
        }
    }
}

// MARK: - Weekly Analysis Card (周分析)
struct WeeklyAnalysisCard: View {
    @ObservedObject var recordService: WellnessRecordService
    
    private var weekStats: WeekStats {
        recordService.getThisWeekStats()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周分析")
                .font(.headline)
                .padding(.horizontal)
            
            // 周数据概览
            HStack(spacing: 12) {
                AnalysisStatItem(title: "饮食记录", value: "\(weekStats.totalMeals)", unit: "次", color: .orange)
                AnalysisStatItem(title: "运动时长", value: "\(weekStats.exerciseMinutes)", unit: "分钟", color: .green)
                AnalysisStatItem(title: "习惯打卡", value: "\(weekStats.habitCompletions)", unit: "次", color: .indigo)
            }
            .padding(.horizontal)
            
            // 分析建议
            AnalysisSuggestionCard(stats: weekStats)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Analysis Stat Item
struct AnalysisStatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Analysis Suggestion Card
struct AnalysisSuggestionCard: View {
    let stats: WeekStats
    
    private var suggestion: String {
        if stats.exerciseMinutes < 100 {
            return "本周运动时长偏少，建议每天增加30分钟以上的运动时间。"
        } else if stats.exerciseMinutes < 30 {
            return "本周运动时间偏少，建议增加运动时长。"
        } else {
            return "本周养生表现良好，继续保持良好的生活习惯！"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text(suggestion)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Monthly Analysis Card (月分析)
struct MonthlyAnalysisCard: View {
    @ObservedObject var recordService: WellnessRecordService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月分析")
                .font(.headline)
                .padding(.horizontal)
            
            // 月度统计
            HStack(spacing: 12) {
                VStack {
                    Text("\(recordService.dietRecords.count)")
                        .font(.title2.bold())
                        .foregroundColor(.orange)
                    Text("饮食记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(recordService.exerciseRecords.count)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    Text("运动记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(recordService.moodRecords.count)")
                        .font(.title2.bold())
                        .foregroundColor(.pink)
                    Text("情绪记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // 月度亮点
            MonthlyHighlightsCard()
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Monthly Highlights Card
struct MonthlyHighlightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本月亮点")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                HighlightItem(icon: "flame.fill", color: .orange, title: "连续打卡", value: "12天")
                HighlightItem(icon: "star.fill", color: .yellow, title: "最佳记录", value: "95分")
                HighlightItem(icon: "heart.fill", color: .pink, title: "养生习惯", value: "5个")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HighlightItem: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trends Analysis Card (趋势分析)
struct TrendsAnalysisCard: View {
    @ObservedObject var recordService: WellnessRecordService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("养生趋势")
                .font(.headline)
                .padding(.horizontal)
            
            // 趋势图表
            TrendsChartView()
                .padding(.horizontal)
            
            // 趋势分析
            TrendsInsightCard()
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Trends Chart View
struct TrendsChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("近30天养生指数变化")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                Path { path in
                    let points: [(CGFloat, CGFloat)] = [
                        (0, 0.4), (0.1, 0.5), (0.2, 0.45), (0.3, 0.6),
                        (0.4, 0.55), (0.5, 0.7), (0.6, 0.65), (0.7, 0.75),
                        (0.8, 0.7), (0.9, 0.8), (1.0, 0.85)
                    ]
                    
                    let xStep = geometry.size.width / CGFloat(points.count - 1)
                    let yScale = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: yScale * (1 - points[0].1)))
                    for (index, point) in points.enumerated() {
                        if index > 0 {
                            path.addLine(to: CGPoint(
                                x: xStep * CGFloat(index),
                                y: yScale * (1 - point.1)
                            ))
                        }
                    }
                }
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
                // 填充区域
                Path { path in
                    let points: [(CGFloat, CGFloat)] = [
                        (0, 0.4), (0.1, 0.5), (0.2, 0.45), (0.3, 0.6),
                        (0.4, 0.55), (0.5, 0.7), (0.6, 0.65), (0.7, 0.75),
                        (0.8, 0.7), (0.9, 0.8), (1.0, 0.85)
                    ]
                    
                    let xStep = geometry.size.width / CGFloat(points.count - 1)
                    let yScale = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: yScale))
                    path.addLine(to: CGPoint(x: 0, y: yScale * (1 - points[0].1)))
                    for (index, point) in points.enumerated() {
                        path.addLine(to: CGPoint(
                            x: xStep * CGFloat(index),
                            y: yScale * (1 - point.1)
                        ))
                    }
                    path.addLine(to: CGPoint(x: geometry.size.width, y: yScale))
                    path.closeSubpath()
                }
                .fill(Color.orange.opacity(0.1))
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Trends Insight Card
struct TrendsInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("趋势洞察")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(icon: "arrow.up.circle.fill", color: .green, title: "持续进步", desc: "养生指数较上周提升8%")
                InsightRow(icon: "star.circle.fill", color: .yellow, title: "保持稳定", desc: "睡眠质量维持在良好水平")
                InsightRow(icon: "arrow.up.arrow.down.circle.fill", color: .orange, title: "需要关注", desc: "建议增加运动频率")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Detailed Records Section (详细记录列表)
struct DetailedRecordsSection: View {
    @ObservedObject var recordService: WellnessRecordService
    @State private var selectedCategory: RecordCategory = .all
    
    enum RecordCategory: String, CaseIterable {
        case all = "全部"
        case diet = "饮食"
        case exercise = "运动"
        case sleep = "睡眠"
        case mood = "情绪"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("详细记录")
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(RecordCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            
            // 记录列表
            VStack(spacing: 8) {
                // 饮食记录
                if selectedCategory == .all || selectedCategory == .diet {
                    ForEach(recordService.dietRecords.prefix(2)) { record in
                        RecordRowItem(record: record)
                    }
                }
                // 运动记录
                if selectedCategory == .all || selectedCategory == .exercise {
                    ForEach(recordService.exerciseRecords.prefix(2)) { record in
                        RecordRowItem(record: record)
                    }
                }
                // 睡眠记录
                if selectedCategory == .all || selectedCategory == .sleep {
                    ForEach(recordService.sleepRecords.prefix(2)) { record in
                        RecordRowItem(record: record)
                    }
                }
                // 情绪记录
                if selectedCategory == .all || selectedCategory == .mood {
                    ForEach(recordService.moodRecords.prefix(2)) { record in
                        RecordRowItem(record: record)
                    }
                }
                
                Button("查看全部记录") {
                    // 跳转到详细记录页面
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

protocol HasDate {
    var date: Date { get }
}

// MARK: - Record Row Item
struct RecordRowItem: View {
    let record: Any
    
    private var icon: String {
        if record is DietRecord { return "fork.knife" }
        if record is ExerciseRecord { return "figure.walk" }
        if record is SleepRecord { return "moon.fill" }
        if record is MoodRecord { return "heart.fill" }
        return "circle"
    }
    
    private var color: Color {
        if record is DietRecord { return .orange }
        if record is ExerciseRecord { return .green }
        if record is SleepRecord { return .indigo }
        if record is MoodRecord { return .pink }
        return .gray
    }
    
    private var title: String {
        if let record = record as? DietRecord {
            return "\(record.mealType.rawValue): \(record.food)"
        }
        if let record = record as? ExerciseRecord {
            return "\(record.type) - \(record.duration)分钟"
        }
        if let record = record as? SleepRecord {
            return "睡眠质量: \(record.quality)%"
        }
        if let record = record as? MoodRecord {
            return "\(record.mood.emoji) \(record.mood.displayName)"
        }
        return "记录"
    }
    
    private var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let record = record as? HasDate {
            return formatter.string(from: record.date)
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppStateService())
}
