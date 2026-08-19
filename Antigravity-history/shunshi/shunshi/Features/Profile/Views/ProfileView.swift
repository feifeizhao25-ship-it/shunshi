import SwiftUI

// MARK: - Profile View (我的)
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var membershipService = EnhancedMembershipService.shared
    @StateObject private var paywallService = SmartPaywallService.shared
    @StateObject private var referralService = ViralReferralService.shared
    @EnvironmentObject private var appState: AppStateService
    @Environment(\.colorScheme) private var colorScheme
    @State private var showReport = false
    @State private var showCalendar = false
    @State private var showFavorites = false
    @State private var showRecords = false
    @State private var showReminders = false
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var showConstitutionDetail = false
    @State private var showGrowthCompass = false
    
    // MARK: - 前四个功能入口的状态
    @State private var showLogin = false
    @State private var showMembership = false
    @State private var showAchievement = false
    @State private var showFamilyCare = false
    
    // MARK: - 新增功能状态
    @State private var showTrialStart = false
    @State private var showReferralRewards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.adaptive(colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // User Header
                        userHeader
                        
                        // Membership Card
                        membershipCard
                        
                        // Zen Growth (The Tree/Streak)
                        zenGrowthCard
                        
                        // Family Care Entry
                        familyCareCard
                        
                        // Constitution Card
                        constitutionCard
                        
                        // Menu Sections
                        menuSection
                        
                        // Settings Section
                        settingsSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSize.tabBarHeight + AppSpacing.lg)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showReport) {
                if let term = appState.currentSolarTerm {
                    WellnessReportView(solarTerm: term)
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView()
            }
            .sheet(isPresented: $showRecords) {
                WellnessRecordsView()
            }
            .sheet(isPresented: $showReminders) {
                ReminderSettingsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpFeedbackView()
            }
            .sheet(isPresented: $showConstitutionDetail) {
                ConstitutionDetailView()
            }
            .sheet(isPresented: $showGrowthCompass) {
                GrowthCompassView()
            }
            // MARK: - 前四个功能入口的 Sheet 跳转
            .sheet(isPresented: $showLogin) {
                LoginView()
            }
            .sheet(isPresented: $showMembership) {
                MembershipPricingView()
            }
            .sheet(isPresented: $showAchievement) {
                AchievementCenterView()
            }
            .sheet(isPresented: $showFamilyCare) {
                NavigationStack {
                    FamilyMemberListView()
                }
            }
            // MARK: - 新增功能 Sheet
            .sheet(isPresented: $showTrialStart) {
                TrialStartView()
            }
            .sheet(isPresented: $showReferralRewards) {
                ReferralRewardsView()
            }
            // MARK: - 智能付费墙
            .sheet(isPresented: $paywallService.shouldShowPaywall) {
                if let trigger = paywallService.currentTrigger {
                    SmartPaywallView(trigger: trigger)
                }
            }
        }
    }
    
    // MARK: - User Header
    // ... (rest of the file with membershipCard added later)
    
    // MARK: - Zen Growth Card (点击跳转成就中心)
    private var zenGrowthCard: some View {
        let stats = viewModel.user?.stats ?? UserStats.empty
        let stageName = WellnessStreakService.shared.stageName(for: stats.zenGrowthStage)
        let emoji = WellnessStreakService.shared.stageEmoji(for: stats.zenGrowthStage)
        
        return Button {
            showAchievement = true
        } label: {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("生命之树 · \(stageName)")
                            .font(AppTypography.headline(16))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("连续养生 \(stats.currentStreak) 天")
                                .font(AppTypography.caption())
                                .foregroundColor(Color.AppText.secondary(colorScheme))
                        }
                    }
                    
                    Spacer()
                    
                    Text(emoji)
                        .font(.system(size: 44))
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.shunshiPrimary.opacity(0.1))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(Color.shunshiPrimary)
                                .frame(width: geo.size.width * CGFloat(min(1.0, Double(stats.currentStreak) / 30.0)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("再坚持 \(max(0, 30 - stats.currentStreak)) 天达到最高境界『硕果累累』")
                        .font(.system(size: 10))
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
            }
            .padding(AppSpacing.lg)
            .lumeGlass()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - User Header (点击跳转登录/个人信息)
    private var userHeader: some View {
        Button {
            if viewModel.isLoggedIn {
                // 已登录：跳转到设置页面编辑个人信息
                showSettings = true
            } else {
                // 未登录：跳转到登录页面
                showLogin = true
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.shunshiPrimary.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.shunshiPrimary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(viewModel.isLoggedIn ? viewModel.displayName : "点击登录")
                        .font(AppTypography.headline(18))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    Text(viewModel.isLoggedIn ? "已同步您的养生数据" : "登录后同步您的养生数据")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
            .padding(AppSpacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Membership Card (增强版)
    private var membershipCard: some View {
        Group {
            if membershipService.isTrialActive {
                // 试用中状态
                TrialActiveCard(daysRemaining: membershipService.getTrialDaysRemaining())
            } else if membershipService.trialStatus == .ended && !membershipService.isPremium {
                // 试用结束，未付费
                TrialEndedCard(onSubscribe: { showMembership = true })
            } else {
                // 普通会员卡片
                Button {
                    if membershipService.isPremium {
                        showMembership = true
                    } else {
                        showTrialStart = true
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: membershipService.isPremium ? "crown.fill" : "gift.fill")
                                    .foregroundColor(.yellow)
                                Text(membershipService.isPremium ? "顺时高级会员" : "免费试用7天")
                                    .font(AppTypography.headline(16))
                                    .foregroundColor(.white)
                            }
                            
                            Text(membershipService.isPremium 
                                ? "解锁 100+ 专属养生秘方与 AI 指导"
                                : "体验完整会员权益，再决定是否订阅")
                                .font(AppTypography.caption())
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        if membershipService.isPremium {
                            Text("立即续费")
                                .font(AppTypography.label())
                                .foregroundColor(.shunshiPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white)
                                .clipShape(Capsule())
                        } else {
                            Text("立即试用")
                                .font(AppTypography.label())
                                .foregroundColor(.shunshiPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(AppSpacing.lg)
                    .background(
                        LinearGradient(
                            colors: membershipService.isPremium 
                                ? [Color.shunshiPrimary, Color.shunshiPrimary.opacity(0.7)]
                                : [Color.orange, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Family Care Card (点击跳转家庭关怀)
    private var familyCareCard: some View {
        Button {
            showFamilyCare = true
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("家庭关怀")
                        .font(AppTypography.headline(16))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    Text("与家人同步健康状态，守护彼此")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
            .padding(AppSpacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Constitution Card
    private var constitutionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("我的体质")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
            
            HStack(spacing: AppSpacing.md) {
                // Primary Constitution
                if let primary = viewModel.user?.constitution?.primary {
                    constitutionTypeView(primary: primary, label: "主体质")
                } else {
                    emptyConstitutionView
                }

                // Secondary Constitution
                if let secondary = viewModel.user?.constitution?.secondary {
                    constitutionTypeView(primary: secondary, label: "兼夹体质")
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            // 导航到体质详情页
            navigateToConstitution()
        }
    }
    
    // 体质类型视图
    private func constitutionTypeView(primary: UserConstitutionResult, label: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(primary.type.themeColor.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: primary.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(primary.type.themeColor)
            }

            Text(primary.type.displayName)
                .font(AppTypography.headline(14))
                .foregroundColor(Color.AppText.primary(colorScheme))

            Text(label)
                .font(AppTypography.label())
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
    
    // 空状态视图
    private var emptyConstitutionView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.shunshiPrimary.opacity(0.5))
            
            Text("尚未测试")
                .font(AppTypography.headline(14))
                .foregroundColor(Color.AppText.muted(colorScheme))
            
            Text("点击开始测试")
                .font(AppTypography.label())
                .foregroundColor(.shunshiPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
    
    // 导航到体质详情页
    private func navigateToConstitution() {
        // 使用sheet展示体质详情
        showConstitutionDetail = true
    }
    
// MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 1) {
            MenuButton(icon: "calendar", title: "节气日历", color: .shunshiPrimary) {
                showCalendar = true
            }
            MenuButton(icon: "compass.drawing", title: "成长罗盘", color: .seasonWinter) {
                showGrowthCompass = true
            }
            MenuButton(icon: "heart.fill", title: "我的收藏", color: .pink) {
                showFavorites = true
            }
            MenuButton(icon: "clock.arrow.circlepath", title: "养生记录", color: .orange) {
                showRecords = true
            }
            Button(action: { showReport = true }) {
                MenuRow(icon: "chart.bar.fill", title: "养生周报", color: .purple)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 1) {
            // 邀请有礼（新增）
            MenuButton(icon: "person.badge.plus", title: "邀请有礼", color: .orange) {
                showReferralRewards = true
            }
            
            MenuButton(icon: "bell.fill", title: "提醒设置", color: .blue) {
                showReminders = true
            }
            MenuButton(icon: "gearshape.fill", title: "设置", color: .gray) {
                showSettings = true
            }
            MenuButton(icon: "questionmark.circle.fill", title: "帮助与反馈", color: .green) {
                showHelp = true
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - 试用中状态卡片
    private struct TrialActiveCard: View {
        let daysRemaining: Int
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            Text("7天免费试用中")
                                .font(AppTypography.headline(16))
                                .foregroundColor(Color.AppText.primary(colorScheme))
                        }
                        
                        Text("还剩\(daysRemaining)天，尽情享受会员权益")
                            .font(AppTypography.caption())
                            .foregroundColor(Color.AppText.secondary(colorScheme))
                    }
                    
                    Spacer()
                    
                    // 剩余天数标签
                    Text("\(daysRemaining)天")
                        .font(AppTypography.label())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                // 进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(7 - daysRemaining) / 7, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(AppSpacing.lg)
            .background(Color.Surface.adaptive(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        }
    }
    
    // MARK: - 试用结束卡片
    private struct TrialEndedCard: View {
        let onSubscribe: () -> Void
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            Button(action: onSubscribe) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "hourglass")
                                .foregroundColor(.red)
                            Text("试用已结束")
                                .font(AppTypography.headline(16))
                                .foregroundColor(Color.AppText.primary(colorScheme))
                        }
                        
                        Text("立即订阅，享受40%限时优惠")
                            .font(AppTypography.caption())
                            .foregroundColor(Color.AppText.secondary(colorScheme))
                    }
                    
                    Spacer()
                    
                    Text("立即订阅")
                        .font(AppTypography.label())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(AppSpacing.lg)
                .background(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Menu Row
struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(title)
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
    }
}

// MARK: - Menu Button (可点击的菜单行)
struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(AppTypography.body())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
            .padding(AppSpacing.md)
            .background(Color.Surface.adaptive(colorScheme))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
