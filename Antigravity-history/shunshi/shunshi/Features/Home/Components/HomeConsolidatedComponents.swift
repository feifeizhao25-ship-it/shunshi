import SwiftUI

// MARK: - Premium Seasonal Hero
struct HomePremiumHero: View {
    let greeting: String
    let userName: String
    let dateText: String
    let completed: Int
    let total: Int
    let solarTerm: SolarTerm?
    let careStatus: AIAgentService.CareStatus? // Phase C: 关心状态可视
    let onSolarTermTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Background Layer (Seasonal Gradient/Image)
            ZStack(alignment: .bottom) {
                if let term = solarTerm {
                    // Modern Seasonal Header with blurred image or gradient
                    LinearGradient(
                        colors: [term.themeColor.opacity(0.8), term.themeColor.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 240)
                    
                    // Decorative element (Planet/Sun/Moon based on term)
                    Circle()
                        .fill(term.themeColor.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: 100, y: -100)
                }
                
                // Content Layer
                VStack(alignment: .leading, spacing: 20) {
                    // Header Row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greeting)，\(userName)")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            
                            Text(dateText)
                                .font(AppTypography.subheadline())
                                .foregroundColor(.white.opacity(0.8))
                            
                            if let status = careStatus {
                                HStack(spacing: 4) {
                                    Image(systemName: statusIcon(for: status))
                                        .font(.system(size: 10))
                                    Text(statusText(for: status))
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(.top, 4)
                            }
                        }
                        
                        Spacer()
                        
                        // Solar Term Badge (Interactive)
                        if let term = solarTerm {
                            Button(action: onSolarTermTap) {
                                VStack(spacing: 4) {
                                    Text(term.name)
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(.white)
                                    Text(term.nameEn)
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Wellness Progress Strip (Integrated)
                    HStack(spacing: AppSpacing.md) {
                        // Small Circular Progress
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 44, height: 44)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("今日养生活度")
                                .font(AppTypography.caption(12))
                                .foregroundColor(.white.opacity(0.9))
                            Text(total > 0 ? "已完成 \(completed)/\(total) 项建议" : "新的一天，探索生活的节奏")
                                .font(AppTypography.caption(11))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Mood Quick Entry (Mini version of DailyPulse)
                        DailyPulseIconRow()
                    }
                    .padding(14)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.shunshiPrimary.opacity(0.1)) // Fallback
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
    
    // MARK: - Helper Methods
    private func statusIcon(for status: AIAgentService.CareStatus) -> String {
        switch status {
        case .stable: return "shield.checkmark.fill"
        case .needsAttention: return "heart.text.square.fill"
        case .escalate: return "exclamationmark.shield.fill"
        }
    }
    
    private func statusText(for status: AIAgentService.CareStatus) -> String {
        switch status {
        case .stable: return "被安稳照顾中"
        case .needsAttention: return "正在重点关注"
        case .escalate: return "需要专业介入"
        }
    }
}

// MARK: - Mini Mood Selector
// MARK: - Mini Mood Selector
struct DailyPulseIconRow: View {
    @StateObject private var healthService = ModernHealthService.shared
    @State private var recordedMood: String? = nil
    
    // (Icon, Title, Score, EmotionTag)
    let moods: [(String, String, Int, ModernEmotionTag)] = [
        ("bolt.fill", "有活力", 9, .energetic),
        ("leaf.fill", "轻松", 8, .calm),
        ("circle.grid.cross.fill", "平稳", 6, .grateful),
        ("moon.zzz.fill", "疲惫", 4, .tired),
        ("wind", "压力", 3, .anxious)
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(moods, id: \.1) { item in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    healthService.upsertTodayMood(
                        moodScore: item.2,
                        emotions: [item.3],
                        note: item.1
                    )
                    withAnimation {
                        recordedMood = item.1
                    }
                } label: {
                    Image(systemName: item.0)
                        .font(.system(size: 14))
                        .foregroundColor(recordedMood == item.1 ? .shunshiPrimary : .white)
                        .frame(width: 32, height: 32)
                        .background(recordedMood == item.1 ? .white : .white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            if let today = healthService.todayMoodRecord() {
                // Simple reverse mapping for display state
                if today.moodScore >= 9 { recordedMood = "有活力" }
                else if today.moodScore >= 8 { recordedMood = "轻松" }
                else if today.moodScore >= 6 { recordedMood = "平稳" }
                else if today.moodScore >= 4 { recordedMood = "疲惫" }
                else { recordedMood = "压力" }
            }
        }
    }
}

// MARK: - Combined Smart AI Hub
// MARK: - Combined Smart AI Hub
struct SmartInsightHub: View {
    @ObservedObject var viewModel: HomeViewModel
    let completed: Int
    let total: Int
    // Nudge Props
    var nudgeTitle: String? = nil
    var nudgeMessage: String? = nil
    var onNudgeAction: (() -> Void)? = nil
    
    let onOpenPlan: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("顺时建议")
                    .font(AppTypography.headline(18))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                // Tab Picker for AI Insights
                HStack(spacing: 12) {
                    insightTab(title: "计划", index: 0)
                    insightTab(title: "陪伴", index: 1)
                    if nudgeTitle != nil {
                        insightTab(title: "提醒", index: 2)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            ZStack {
                switch selectedTab {
                case 0:
                    // Plan Insight
                    insightCardContent(
                        icon: "list.bullet.rectangle",
                        title: viewModel.dailyPlanFocus,
                        subtitle: viewModel.dailyPlanSummary,
                        action: "查看每日计划",
                        onAction: onOpenPlan
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case 1:
                    // Companion/Mood Insight
                    insightCardContent(
                        icon: "sparkles",
                        title: "当前建议",
                        subtitle: viewModel.dailyCompanionMessage,
                        action: "了解更多",
                        onAction: onOpenPlan
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case 2:
                    // Nudge Insight
                    if let title = nudgeTitle, let message = nudgeMessage {
                        insightCardContent(
                            icon: "bell.fill",
                            title: title,
                            subtitle: message,
                            action: "去处理",
                            onAction: onNudgeAction ?? onOpenPlan
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    }
                default:
                    EmptyView()
                }
            }
        }
        .onAppear {
            // Auto switch to Nudge if present and important
            if nudgeTitle != nil {
                selectedTab = 2
            }
        }
    }
    
    private func insightTab(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: selectedTab == index ? .bold : .medium))
                .foregroundColor(selectedTab == index ? .shunshiPrimary : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedTab == index ? Color.shunshiPrimary.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
        }
    }
    
    private func insightCardContent(icon: String, title: String, subtitle: String, action: String, onAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.shunshiPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.headline(16))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    Text(subtitle)
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                        .lineLimit(2)
                }
            }
            
            Button(action: onAction) {
                HStack {
                    Text(action)
                        .font(AppTypography.label(14))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.shunshiPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .softShadow()
    }
}

// MARK: - Health Toolbox Grid
struct HealthToolboxGrid: View {
    let actions: [HomeQuickAction]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康工具箱")
                .font(AppTypography.headline(18))
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(actions.prefix(4)) { action in
                    NavigationLink(destination: action.destination) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(action.color.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: action.icon)
                                    .foregroundColor(action.color)
                                    .font(.system(size: 16))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(AppTypography.headline(14))
                                    .foregroundColor(Color.AppText.primary(colorScheme))
                                Text(action.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.AppText.muted(colorScheme))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.Surface.adaptive(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
