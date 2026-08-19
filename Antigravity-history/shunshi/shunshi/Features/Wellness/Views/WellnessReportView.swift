import SwiftUI

// MARK: - Wellness Report View
struct WellnessReportView: View {
    let solarTerm: SolarTerm
    let constitution: String
    @StateObject private var viewModel = WellnessReportViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSuccessToast = false
    @State private var selectedSection: ReportSection? = .overview
    
    enum ReportSection: String, CaseIterable {
        case overview = "概览"
        case sleep = "睡眠"
        case nutrition = "营养"
        case mood = "情志"
        case exercise = "运动"
        case suggestions = "建议"
    }
    
    init(solarTerm: SolarTerm, constitution: String = "平和质") {
        self.solarTerm = solarTerm
        self.constitution = constitution
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Report Content
                        reportContent
                            .padding()
                        
                        // Action Tips
                        Text("这份周报见证了你本周的每一次坚持")
                            .font(AppTypography.caption())
                            .foregroundColor(.gray)
                            .padding(.top, -10)
                        
                        // Share Buttons
                        shareButtonsSection
                            .padding(.bottom, AppSpacing.xxl)
                    }
                }
                .background(Color.Background.adaptive(colorScheme))
                
                // Toast
                if showSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.white)
                            Text("已成功保存至相册")
                                .font(AppTypography.subheadline())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("养生周报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { showSuccessToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccessToast = false }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .task {
                viewModel.generateComprehensiveReport(solarTerm: solarTerm.name, constitution: constitution)
            }
        }
    }
    
    // MARK: - Report Content
    
    private var reportContent: some View {
        VStack(spacing: 0) {
            // Top Section with texture
            ZStack {
                // Background texture
                Color(hexCode: "#F9F6F0")
                
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    reportHeader
                    
                    // Date Title
                    solarTermSection
                    
                    Divider().background(Color.shunshiPrimary.opacity(0.2))
                    
                    // Fusion Score Section
                    fusionScoreSection
                    
                    Divider().background(Color.shunshiPrimary.opacity(0.2))
                    
                    // Weekly Overview
                    weeklyOverviewSection
                    
                    Divider().background(Color.shunshiPrimary.opacity(0.2))
                    
                    // Four Dimensions Analysis
                    fourDimensionsSection
                    
                    Divider().background(Color.shunshiPrimary.opacity(0.2))
                    
                    // Integrated Suggestions
                    integratedSuggestionsSection
                    
                    Divider().background(Color.shunshiPrimary.opacity(0.2))

                    // Phase B: 连续性关怀总结 (Premium Only)
                    if viewModel.isPremium {
                        careSummarySection
                        Divider().background(Color.shunshiPrimary.opacity(0.2))
                    }
                    
                    // AI Insight
                    aiInsightSection
                }
                .padding(24)
            }
            .cornerRadius(AppRadius.xl, corners: [.topLeft, .topRight])
            
            // Bottom Decorative Strip
            HStack {
                Text("顺应天时 · 万物可期 · 古今融合")
                    .font(AppTypography.caption(12))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Image(systemName: "qrcode")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.shunshiPrimary)
            .cornerRadius(AppRadius.xl, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
    }
    
    // MARK: - Header
    
    private var reportHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("顺时 SHUNSHI")
                    .font(AppTypography.headline(14))
                    .tracking(2)
                    .foregroundColor(.shunshiPrimary)
                Text("融合养生档案 · 周报")
                    .font(AppTypography.caption(10))
                    .foregroundColor(.shunshiPrimary.opacity(0.6))
            }
            Spacer()
            // Seal decoration
            VStack(spacing: 2) {
                Text("顺")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(4)
                    .overlay(
                        Rectangle().stroke(Color.red, lineWidth: 1).padding(-2)
                    )
                Text("古今")
                    .font(.system(size: 8))
                    .foregroundColor(.shunshiPrimary)
            }
        }
    }
    
    // MARK: - Solar Term Section
    
    private var solarTermSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(solarTerm.name)
                    .font(AppTypography.solarTermTitle(36))
                    .foregroundColor(Color(hexCode: "#2C2C2C"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(constitution)
                        .font(AppTypography.subheadline(12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.shunshiPrimary.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.shunshiPrimary)
                    
                    Text(solarTerm.healthPrinciple)
                        .font(AppTypography.caption(10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Text("\(viewModel.startDate.formatted("yyyy.MM.dd")) - \(viewModel.endDate.formatted("yyyy.MM.dd"))")
                .font(AppTypography.caption(12))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Fusion Score Section
    
    private var fusionScoreSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("融合健康评分")
                        .font(AppTypography.sectionTitle(16))
                        .foregroundColor(.shunshiPrimary)
                    Text("传统中医 × 现代科学")
                        .font(AppTypography.caption(11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Main Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.traditionalModernFusionScore / 100)
                        .stroke(
                            fusionScoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.traditionalModernFusionScore))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(fusionScoreColor)
                        Text("分")
                            .font(AppTypography.caption(10))
                            .foregroundColor(.gray)
                    }
                }
                
                // Score Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    ScoreBreakdownRow(
                        icon: "leaf.fill",
                        label: "传统合规",
                        score: calculateTraditionalScore(),
                        color: .green
                    )
                    ScoreBreakdownRow(
                        icon: "waveform.path.ecg",
                        label: "现代指标",
                        score: calculateModernScore(),
                        color: .blue
                    )
                    ScoreBreakdownRow(
                        icon: "scale.3d",
                        label: "身心平衡",
                        score: calculateBalanceScore(),
                        color: .orange
                    )
                    ScoreBreakdownRow(
                        icon: "clock.arrow.circlepath",
                        label: "习惯一致",
                        score: viewModel.weeklySleepAnalysis.consistencyScore,
                        color: .purple
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Score Interpretation
            HStack {
                Image(systemName: fusionScoreIcon)
                    .foregroundColor(fusionScoreColor)
                Text(fusionScoreInterpretation)
                    .font(AppTypography.caption(12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(fusionScoreColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    private var fusionScoreColor: Color {
        let score = viewModel.traditionalModernFusionScore
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private var fusionScoreIcon: String {
        let score = viewModel.traditionalModernFusionScore
        if score >= 80 { return "checkmark.seal.fill" }
        if score >= 60 { return "exclamationmark.triangle.fill" }
        return "arrow.up.circle.fill"
    }
    
    private var fusionScoreInterpretation: String {
        let score = viewModel.traditionalModernFusionScore
        if score >= 80 { return "融合养生状态优秀，古今智慧平衡得当" }
        if score >= 60 { return "整体状态良好，部分维度有提升空间" }
        return "建议关注优先级建议，逐步改善健康习惯"
    }
    
    // MARK: - Weekly Overview Section
    
    private var weeklyOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("本周概览")
                    .font(AppTypography.sectionTitle(16))
                    .foregroundColor(.shunshiPrimary)
                Spacer()
            }
            
            HStack(spacing: 0) {
                OverviewStatView(
                    title: "打卡天数",
                    value: "\(viewModel.weeklyOverview.checkInDays)",
                    unit: "天",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                Divider().frame(height: 40).opacity(0.3)
                OverviewStatView(
                    title: "睡眠均值",
                    value: String(format: "%.1f", viewModel.weeklyOverview.sleepAverage),
                    unit: "h",
                    icon: "moon.fill",
                    color: .indigo
                )
                Divider().frame(height: 40).opacity(0.3)
                OverviewStatView(
                    title: "情绪稳定",
                    value: String(format: "%.0f", viewModel.weeklyOverview.moodStability),
                    unit: "%",
                    icon: "heart.fill",
                    color: .pink
                )
                Divider().frame(height: 40).opacity(0.3)
                OverviewStatView(
                    title: "运动天数",
                    value: "\(viewModel.weeklyOverview.exerciseDays)",
                    unit: "天",
                    icon: "figure.walk",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Four Dimensions Section
    
    private var fourDimensionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("四维深度分析")
                    .font(AppTypography.sectionTitle(16))
                    .foregroundColor(.shunshiPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Sleep Analysis Card
                DimensionAnalysisCard(
                    icon: "moon.stars.fill",
                    title: "睡眠分析",
                    subtitle: "亥时入眠 · 养藏之道",
                    color: .indigo,
                    score: min(viewModel.weeklySleepAnalysis.averageDuration / 8 * 100, 100)
                ) {
                    sleepAnalysisContent
                }
                
                // Nutrition Analysis Card
                DimensionAnalysisCard(
                    icon: "leaf.fill",
                    title: "营养分析",
                    subtitle: "节气食养 · 膳食平衡",
                    color: .green,
                    score: (viewModel.weeklyNutritionAnalysis.proteinAdequacy + viewModel.weeklyNutritionAnalysis.waterAdequacy) / 2
                ) {
                    nutritionAnalysisContent
                }
                
                // Mood Analysis Card
                DimensionAnalysisCard(
                    icon: "heart.fill",
                    title: "情志分析",
                    subtitle: "七情调和 · 心境平和",
                    color: .pink,
                    score: viewModel.weeklyMoodAnalysis.averageScore * 10
                ) {
                    moodAnalysisContent
                }
                
                // Exercise Analysis Card
                DimensionAnalysisCard(
                    icon: "figure.mind.and.body",
                    title: "运动分析",
                    subtitle: "动静结合 · 形神共养",
                    color: .orange,
                    score: viewModel.weeklyExerciseAnalysis.goalAchievement
                ) {
                    exerciseAnalysisContent
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Analysis Content Views
    
    private var sleepAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("平均时长: \(String(format: "%.1f", viewModel.weeklySleepAnalysis.averageDuration))小时", systemImage: "clock")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("早睡\(viewModel.weeklySleepAnalysis.earlySleepDays)天", systemImage: "moon.zzz")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            HStack {
                Label("平均入睡: \(viewModel.weeklySleepAnalysis.bedTimeAverage)", systemImage: "bed.double")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("深度睡眠: \(String(format: "%.0f", viewModel.weeklySleepAnalysis.deepSleepPercentage))%", systemImage: "waveform.path")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            if !viewModel.weeklySleepAnalysis.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.weeklySleepAnalysis.issues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(issue)
                                .font(AppTypography.caption(11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Traditional perspective
            Text("传统视角: \(solarTerm.name)宜亥时(21-23点)入睡，养藏阳气。\(constitution)者更需注意早睡养气血。")
                .font(AppTypography.caption(11))
                .foregroundColor(.shunshiPrimary)
                .padding(.top, 4)
        }
    }
    
    private var nutritionAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("平均热量: \(Int(viewModel.weeklyNutritionAnalysis.averageCalories))kcal", systemImage: "flame")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("蛋白质达标: \(Int(viewModel.weeklyNutritionAnalysis.proteinAdequacy))%", systemImage: "fish")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            HStack {
                Label("饮水达标: \(Int(viewModel.weeklyNutritionAnalysis.waterAdequacy))%", systemImage: "drop")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("三餐规律: \(Int(viewModel.weeklyNutritionAnalysis.mealRegularity))%", systemImage: "clock")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            // Macro breakdown
            HStack(spacing: 8) {
                MacroBar(label: "蛋", value: viewModel.weeklyNutritionAnalysis.macroBalance.protein, color: .blue)
                MacroBar(label: "碳", value: viewModel.weeklyNutritionAnalysis.macroBalance.carbs, color: .green)
                MacroBar(label: "脂", value: viewModel.weeklyNutritionAnalysis.macroBalance.fat, color: .orange)
            }
            .padding(.top, 4)
            
            if !viewModel.weeklyNutritionAnalysis.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.weeklyNutritionAnalysis.issues.prefix(2), id: \.self) { issue in
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(issue)
                                .font(AppTypography.caption(11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Traditional perspective
            let isWinter = solarTerm.name.contains("冬") || solarTerm.name.contains("雪") || solarTerm.name.contains("寒")
            Text("传统视角: \(isWinter ? "\\(solarTerm.name)宜温补，多食温阳食材" : "\\(solarTerm.name)宜顺应天时，选择当季食材")。黑色食物入肾，既合中医理论又富营养。")
                .font(AppTypography.caption(11))
                .foregroundColor(.shunshiPrimary)
                .padding(.top, 4)
        }
    }
    
    private var moodAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("平均情绪: \(String(format: "%.1f", viewModel.weeklyMoodAnalysis.averageScore))/10", systemImage: "face.smiling")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("积极天数: \(viewModel.weeklyMoodAnalysis.positiveDays)天", systemImage: "sun.max")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            HStack {
                Label("压力水平: \(stressLevelText)", systemImage: "waveform")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("情绪稳定: \(Int(viewModel.weeklyMoodAnalysis.emotionalStability))%", systemImage: "chart.line.uptrend.xyaxis")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            if !viewModel.weeklyMoodAnalysis.topEmotions.isEmpty {
                HStack(spacing: 8) {
                    Text("主要情绪:")
                        .font(AppTypography.caption(11))
                        .foregroundColor(.secondary)
                    ForEach(viewModel.weeklyMoodAnalysis.topEmotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(AppTypography.caption(10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.pink)
                    }
                }
                .padding(.top, 4)
            }
            
            // Traditional perspective
            Text("传统视角: \(solarTerm.name)时节\(constitution)者宜保持心境平和，可通过静坐、冥想调养心神，实现'恬淡虚无，真气从之'。")
                .font(AppTypography.caption(11))
                .foregroundColor(.shunshiPrimary)
                .padding(.top, 4)
        }
    }
    
    private var stressLevelText: String {
        switch viewModel.weeklyMoodAnalysis.stressLevel {
        case "low": return "偏低 ✓"
        case "moderate": return "适中"
        case "high": return "偏高 ⚠"
        default: return "--"
        }
    }
    
    private var exerciseAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("总时长: \(Int(viewModel.weeklyExerciseAnalysis.totalMinutes))分钟", systemImage: "clock.arrow.circlepath")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("活跃天数: \(viewModel.weeklyExerciseAnalysis.activeDays)天", systemImage: "figure.walk")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            HStack {
                Label("强度: \(intensityText)", systemImage: "flame")
                    .font(AppTypography.caption(12))
                Spacer()
                Label("传统运动: \(viewModel.weeklyExerciseAnalysis.traditionalExerciseDays)天", systemImage: "figure.tai.chi")
                    .font(AppTypography.caption(12))
            }
            .foregroundColor(.secondary)
            
            HStack {
                Label("消耗: \(Int(viewModel.weeklyExerciseAnalysis.caloriesBurned))kcal", systemImage: "bolt")
                    .font(AppTypography.caption(12))
                Spacer()
                if viewModel.weeklyExerciseAnalysis.sedentaryDays > 2 {
                    Label("久坐: \(viewModel.weeklyExerciseAnalysis.sedentaryDays)天", systemImage: "exclamationmark.triangle")
                        .font(AppTypography.caption(12))
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(.secondary)
            
            // Traditional perspective
            Text("传统视角: \(constitution)者宜选择八段锦、太极拳等柔和运动，顺应\(solarTerm.name)节气特点，实现'形劳而不倦'。")
                .font(AppTypography.caption(11))
                .foregroundColor(.shunshiPrimary)
                .padding(.top, 4)
        }
    }
    
    private var intensityText: String {
        switch viewModel.weeklyExerciseAnalysis.averageIntensity {
        case "light": return "轻度"
        case "moderate": return "中等"
        case "vigorous": return "较高"
        default: return "--"
        }
    }
    
    // MARK: - Integrated Suggestions Section
    
    private var integratedSuggestionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("综合建议")
                        .font(AppTypography.sectionTitle(16))
                        .foregroundColor(.shunshiPrimary)
                    Text("古今融合 · 个性定制")
                        .font(AppTypography.caption(11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            if viewModel.integratedSuggestions.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("本周状态良好，继续保持！")
                        .font(AppTypography.body(14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(16)
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.integratedSuggestions.prefix(3)) { suggestion in
                        IntegratedSuggestionCard(suggestion: suggestion)
                    }
                }
            }
            
            // Top Priority Action
            if let topSuggestion = viewModel.integratedSuggestions.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("优先级行动")
                            .font(AppTypography.subheadline(14))
                            .foregroundColor(.shunshiPrimary)
                        Spacer()
                        PriorityBadge(priority: topSuggestion.priority)
                    }
                    
                    Text(topSuggestion.fusionInsight)
                        .font(AppTypography.caption(12))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(topSuggestion.color.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(topSuggestion.color.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Care Summary Section (Premium)
    
    private var careSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("关怀历程")
                    .font(AppTypography.sectionTitle(16))
                    .foregroundColor(.shunshiPrimary)
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Premium")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(4)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(4)
            }
            
            // 状态时间轴 (Real Data)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.careTimeline.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        // Time & Line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(item.status == "escalate" ? Color.red : (item.status == "needs_attention" ? Color.orange : Color.green))
                                .frame(width: 8, height: 8)
                            if index < viewModel.careTimeline.count - 1 {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.dateResult)
                                .font(AppTypography.caption(10))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(item.statusTitle)
                                    .font(AppTypography.body(14))
                                    .foregroundColor(.primary)
                                
                                if item.status == "escalate" {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption2)
                                } else if item.status == "needs_attention" {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                }
                            }
                            
                            Text(item.detail)
                                .font(AppTypography.caption(12))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, index < viewModel.careTimeline.count - 1 ? 16 : 0)
                    }
                }
                
                if viewModel.careTimeline.isEmpty {
                    Text("暂无关怀记录")
                        .font(AppTypography.caption())
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.5))
            .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }

    // MARK: - AI Insight Section
    
    private var aiInsightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(.shunshiPrimary.opacity(0.3))
                    .font(.title)
                Text("小顺 · AI综合洞察")
                    .font(AppTypography.sectionTitle(16))
                    .foregroundColor(.shunshiPrimary)
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI")
                        .font(.caption2)
                }
                .foregroundColor(.shunshiPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.shunshiPrimary.opacity(0.1))
                .cornerRadius(4)
            }
            
            Text(viewModel.aiInsight)
                .font(AppTypography.body(14))
                .lineSpacing(6)
                .foregroundColor(Color(hexCode: "#4A4A4A"))
            
            HStack {
                Spacer()
                Image(systemName: "quote.closing")
                    .foregroundColor(.shunshiPrimary.opacity(0.3))
                    .font(.title)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.shunshiPrimary.opacity(0.05), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.shunshiPrimary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Share Buttons Section
    
    private var shareButtonsSection: some View {
        VStack(spacing: 20) {
            Text("分享这份坚持")
                .font(AppTypography.caption())
                .foregroundColor(.gray)
            
            HStack(spacing: 30) {
                ShareActionButton(title: "微信好友", icon: "message.fill", color: .green)
                ShareActionButton(title: "朋友圈", icon: "circle.circle", color: .blue)
                ShareActionButton(title: "保存图片", icon: "arrow.down.to.line", color: .orange)
                    .onTapGesture {
                        withAnimation { showSuccessToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccessToast = false }
                        }
                    }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateTraditionalScore() -> Double {
        var score = 70.0
        score += Double(viewModel.weeklySleepAnalysis.earlySleepDays) * 3
        score += Double(viewModel.weeklyExerciseAnalysis.traditionalExerciseDays) * 4
        if viewModel.weeklyMoodAnalysis.stressLevel == "low" { score += 10 }
        return min(score, 100)
    }
    
    private func calculateModernScore() -> Double {
        let sleepScore = min(viewModel.weeklySleepAnalysis.averageDuration / 8 * 100, 100)
        let nutritionScore = (viewModel.weeklyNutritionAnalysis.proteinAdequacy + viewModel.weeklyNutritionAnalysis.waterAdequacy) / 2
        let exerciseScore = viewModel.weeklyExerciseAnalysis.goalAchievement
        let moodScore = viewModel.weeklyMoodAnalysis.averageScore * 10
        return (sleepScore + nutritionScore + exerciseScore + moodScore) / 4
    }
    
    private func calculateBalanceScore() -> Double {
        var score = 70.0
        score += Double(viewModel.weeklyExerciseAnalysis.activeDays) * 3
        if viewModel.weeklyMoodAnalysis.stressLevel == "low" { score += 15 }
        else if viewModel.weeklyMoodAnalysis.stressLevel == "moderate" { score += 5 }
        return min(score, 100)
    }
}

// MARK: - Supporting Views

struct ScoreBreakdownRow: View {
    let icon: String
    let label: String
    let score: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(AppTypography.caption(11))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(Int(score))")
                .font(AppTypography.subheadline(12))
                .foregroundColor(color)
        }
    }
}

struct OverviewStatView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTypography.headline(16))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(AppTypography.caption(10))
                    .foregroundColor(.gray)
            }
            Text(title)
                .font(AppTypography.caption(10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DimensionAnalysisCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let score: Double
    @ViewBuilder let content: Content
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AppTypography.subheadline(14))
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(AppTypography.caption(10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Score indicator
                    Text("\(Int(score))")
                        .font(AppTypography.subheadline(14))
                        .foregroundColor(scoreColor)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

struct MacroBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(value / 100, 1)))
                }
            }
            .frame(height: 8)
            Text("\(Int(value))%")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .frame(height: 12)
    }
}

struct IntegratedSuggestionCard: View {
    let suggestion: IntegratedSuggestion
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: suggestion.icon)
                    .font(.title3)
                    .foregroundColor(suggestion.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(AppTypography.subheadline(14))
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Text(suggestion.category)
                            .font(AppTypography.caption(10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(suggestion.color.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(suggestion.color)
                        
                        PriorityBadge(priority: suggestion.priority)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showDetail.toggle()
                    }
                } label: {
                    Image(systemName: showDetail ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if showDetail {
                VStack(alignment: .leading, spacing: 10) {
                    AdviceRow(
                        icon: "leaf.fill",
                        title: "传统建议",
                        content: suggestion.traditionalAdvice,
                        color: .green
                    )
                    
                    AdviceRow(
                        icon: "waveform.path.ecg",
                        title: "现代建议",
                        content: suggestion.modernAdvice,
                        color: .blue
                    )
                    
                    AdviceRow(
                        icon: "sparkles",
                        title: "融合洞察",
                        content: suggestion.fusionInsight,
                        color: .purple
                    )
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(suggestion.color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(suggestion.color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AdviceRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption(10))
                    .foregroundColor(color)
                Text(content)
                    .font(AppTypography.caption(11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

struct PriorityBadge: View {
    let priority: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<priority, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 6))
            }
        }
        .foregroundColor(priorityColor)
    }
    
    private var priorityColor: Color {
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTypography.headline(16))
            Text(title)
                .font(AppTypography.caption(11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShareActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(title)
                .font(AppTypography.caption(11))
        }
    }
}

// MARK: - Preview
#Preview {
    WellnessReportView(solarTerm: .preview, constitution: "气虚质")
        .preferredColorScheme(.light)
}

// MARK: - Preview
#Preview {
    WellnessReportView(solarTerm: .preview, constitution: "气虚质")
        .preferredColorScheme(.light)
}
