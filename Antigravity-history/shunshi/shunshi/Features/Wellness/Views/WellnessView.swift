import SwiftUI

// MARK: - Wellness View (五维养生详细内容)
struct WellnessView: View {
    @EnvironmentObject private var appStateService: AppStateService
    @StateObject private var coordinator = WellnessTaskCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showOverview = true
    @State private var showModernWellness = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.adaptive(colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if showOverview {
                        // 五维养生概览页
                        wellnessOverview
                    } else {
                        // Content
                        TabView(selection: $appStateService.selectedWellnessTab) {
                            DietView()
                                .tag(WuWeiType.diet)
                            
                            LivingView()
                                .tag(WuWeiType.living)
                            
                            ExerciseView()
                                .tag(WuWeiType.exercise)
                            
                            AcupointView()
                                .tag(WuWeiType.acupoint)
                            
                            EmotionView()
                                .tag(WuWeiType.emotion)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        // Custom Tab Bar at bottom
                        wuWeiTabBar
                    }
                }
            }
            .navigationTitle(showOverview ? "五维养生" : appStateService.selectedWellnessTab.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showOverview {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showOverview = true
                            }
                            hapticFeedback()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("返回")
                            }
                            .foregroundColor(.shunshiPrimary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("养生报告", systemImage: "chart.bar.doc")
                        }
                        Button(action: {}) {
                            Label("历史记录", systemImage: "clock")
                        }
                        Button(action: {}) {
                            Label("收藏管理", systemImage: "heart")
                        }
                        Button(action: { showModernWellness = true }) {
                            Label("现代养生", systemImage: "waveform.path.ecg")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.shunshiPrimary)
                    }
                }
            }
            .sheet(isPresented: $showModernWellness) {
                ModernWellnessHubView()
            }
        }
    }
    
    // MARK: - 五维养生概览页
    private var wellnessOverview: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // 今日进度卡片（与首页联动）
                todayProgressCard
                
                // 当前节气 Banner
                solarTermBanner
                
                // 五个维度入口卡片
                VStack(spacing: AppSpacing.md) {
                    ForEach(WuWeiType.allCases) { type in
                        wellnessDimensionCard(for: type)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                modernWellnessEntryCard
                    .padding(.horizontal, AppSpacing.md)
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.top, AppSpacing.md)
        }
    }
    
    // MARK: - 今日进度卡片
    private var todayProgressCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日养生进度")
                        .font(AppTypography.headline(16))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    Text("\(coordinator.wellnessProgress.completedTasks)/\(coordinator.wellnessProgress.totalTasks) 已完成")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.AppText.muted(colorScheme).opacity(0.2), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0, to: coordinator.wellnessProgress.progress)
                        .stroke(
                            AngularGradient(
                                colors: [.shunshiPrimary, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5), value: coordinator.wellnessProgress.progress)
                    
                    if coordinator.wellnessProgress.progress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("\(Int(coordinator.wellnessProgress.progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                    }
                }
            }
            
            // 已完成维度标签
            if !coordinator.wellnessProgress.completedDimensions.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(coordinator.wellnessProgress.completedDimensions), id: \.self) { dimension in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text(dimension.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(Color.AppText.secondary(colorScheme))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // 跳转到首页任务的提示
            if coordinator.wellnessProgress.progress < 1.0 {
                Button(action: {
                    // 切换到首页
                    appStateService.selectedTab = .home
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 12))
                        Text("去首页查看今日任务")
                            .font(.caption)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.shunshiPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - 节气 Banner
    private var solarTermBanner: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: appStateService.currentSolarTerm?.icon ?? "leaf.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.shunshiPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("当前节气")
                    .font(AppTypography.label(12))
                    .foregroundColor(.secondary)
                
                Text(appStateService.currentSolarTerm?.name ?? "立春")
                    .font(AppTypography.headline(18))
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("养生重点")
                    .font(AppTypography.label(12))
                    .foregroundColor(.secondary)
                
                Text("温补养阳")
                    .font(AppTypography.subheadline(15))
                    .foregroundColor(.orange)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - 五维度卡片
    private func wellnessDimensionCard(for type: WuWeiType) -> some View {
        // 获取今日推荐
        let todayRec = coordinator.getTodayRecommendation(for: type.toWellnessDimension())
        // 检查是否已完成
        let isCompleted = coordinator.wellnessProgress.completedDimensions.contains(type.toWellnessDimension())
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showOverview = false
                appStateService.selectedWellnessTab = type
            }
            hapticFeedback()
        }) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(type.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(type.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(type.displayName)
                            .font(AppTypography.subheadline(16))
                            .fontWeight(.medium)
                            .foregroundColor(Color.AppText.primary(colorScheme))
                        
                        Text(type.modernAlias)
                            .font(.system(size: 11))
                            .foregroundColor(Color.AppText.muted(colorScheme))
                        
                        if isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let rec = todayRec {
                        Text("今日推荐：\(rec)")
                            .font(AppTypography.caption(12))
                            .foregroundColor(.shunshiPrimary)
                            .lineLimit(1)
                    } else {
                        Text(type.detailedExplanation)
                            .font(AppTypography.caption(12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
            .background(Color.Surface.adaptive(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Enhanced WuWei Tab Bar
    private var wuWeiTabBar: some View {
        VStack(spacing: 0) {
            // Progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color.shunshiPrimary)
                        .frame(width: geometry.size.width / CGFloat(WuWeiType.allCases.count), height: 2)
                        .offset(x: geometry.size.width / CGFloat(WuWeiType.allCases.count) * CGFloat(WuWeiType.allCases.firstIndex(of: appStateService.selectedWellnessTab) ?? 0))
                        .animation(.easeInOut(duration: 0.25), value: appStateService.selectedWellnessTab)
                }
            }
            .frame(height: 2)
            
            HStack(spacing: 0) {
                ForEach(WuWeiType.allCases) { type in
                    wellnessTabButton(for: type)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Rectangle()
                    .fill(Color.Surface.adaptive(colorScheme))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
            )
        }
    }
    
    private func wellnessTabButton(for type: WuWeiType) -> some View {
        let isSelected = appStateService.selectedWellnessTab == type
        let dimension = type.toWellnessDimension()
        let isCompleted = coordinator.wellnessProgress.completedDimensions.contains(dimension)
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                appStateService.selectedWellnessTab = type
            }
            hapticFeedback()
        }) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.shunshiPrimary.opacity(0.15))
                            .frame(width: 44, height: 44)
                    }
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .shunshiPrimary : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isSelected)
                    
                    // 完成标记
                    if isCompleted {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            Spacer()
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                
                Text(type.displayName)
                    .font(AppTypography.caption(10))
                    .foregroundColor(isSelected ? .shunshiPrimary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Modern Wellness Entry Card
    private var modernWellnessEntryCard: some View {
        Button(action: { showModernWellness = true }) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color.shunshiPrimary.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 24))
                        .foregroundColor(.shunshiPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("现代养生")
                        .font(AppTypography.subheadline(16))
                        .fontWeight(.medium)
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    Text("营养 · 睡眠 · 运动 · 情绪")
                        .font(AppTypography.caption(12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
            .background(Color.Surface.adaptive(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Wellness Hub View
struct ModernWellnessHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var modernHealthService = ModernHealthService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("现代养生")
                        .font(AppTypography.headline(20))
                        .foregroundColor(Color.AppText.primary(colorScheme))

                    Text("与节气/体质联动的现代健康方案")
                        .font(AppTypography.body(13))
                        .foregroundColor(Color.AppText.secondary(colorScheme))

                    modernOverviewCard

                    modernCategoryGrid

                    modernSuggestionCard
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.Background.adaptive(colorScheme))
            .navigationTitle("现代养生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var modernOverviewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.shunshiPrimary)
                Text("今日现代健康概览")
                    .font(AppTypography.subheadline(15))
                Spacer()
            }

            HStack(spacing: AppSpacing.md) {
                modernStatItem(title: "热量", value: "\(Int(modernHealthService.todayNutrition.totalCalories))", unit: "kcal")
                modernStatItem(title: "睡眠", value: String(format: "%.1f", modernHealthService.todaySleep.averageDuration), unit: "h")
                modernStatItem(title: "情绪", value: String(format: "%.1f", modernHealthService.todayMood.averageScore), unit: "分")
                modernStatItem(title: "运动", value: "\(Int(modernHealthService.todayExercise.totalMinutes))", unit: "min")
            }
        }
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var modernCategoryGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("现代养生分类")
                .font(AppTypography.subheadline(15))
                .foregroundColor(Color.AppText.primary(colorScheme))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                modernCategoryCard(title: "营养摄入", subtitle: "能量与宏量营养", icon: "fork.knife", color: .orange)
                modernCategoryCard(title: "睡眠修复", subtitle: "时长与质量", icon: "moon.fill", color: .indigo)
                modernCategoryCard(title: "情绪平衡", subtitle: "压力与心境", icon: "heart.fill", color: .pink)
                modernCategoryCard(title: "运动处方", subtitle: "强度与消耗", icon: "figure.run", color: .green)
            }
        }
    }

    private var modernSuggestionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.shunshiPrimary)
                Text("今日现代建议")
                    .font(AppTypography.subheadline(15))
                Spacer()
            }

            Text("结合节气与现代健康数据，建议控制晚餐热量并保持舒缓运动。")
                .font(AppTypography.body(12))
                .foregroundColor(Color.AppText.secondary(colorScheme))
        }
        .padding(AppSpacing.md)
        .background(Color.shunshiPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func modernStatItem(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.label(10))
                .foregroundColor(Color.AppText.secondary(colorScheme))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTypography.subheadline(14))
                    .fontWeight(.semibold)
                Text(unit)
                    .font(AppTypography.label(9))
                    .foregroundColor(Color.AppText.secondary(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func modernCategoryCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(title)
                .font(AppTypography.subheadline(14))
                .foregroundColor(Color.AppText.primary(colorScheme))
            Text(subtitle)
                .font(AppTypography.label(10))
                .foregroundColor(Color.AppText.secondary(colorScheme))
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - WuWeiType Extension
extension WuWeiType {
    func toWellnessDimension() -> WellnessDimension {
        switch self {
        case .diet: return .diet
        case .living: return .living
        case .exercise: return .exercise
        case .acupoint: return .acupoint
        case .emotion: return .emotion
        }
    }
}

// MARK: - Preview
#Preview {
    WellnessView()
        .preferredColorScheme(.dark)
        .environmentObject(AppStateService.shared)
}
