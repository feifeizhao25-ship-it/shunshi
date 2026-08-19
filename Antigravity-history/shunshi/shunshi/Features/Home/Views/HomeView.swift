import Foundation
import SwiftUI

// MARK: - Home View (个人仪表盘)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appState: AppStateService
    @StateObject private var recordService = WellnessRecordService.shared
    @StateObject private var modernHealthService = ModernHealthService.shared
    @StateObject private var taskCoordinator = WellnessTaskCoordinator.shared
    @StateObject private var challengeService = MicroHabitChallengeService.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showConsultant = false
    @State private var showObservation = false
    @State private var showDailyPlan = false
    @State private var showBreathing = false
    @State private var showHabitCheckin = false
    @State private var showConstitutionTest = false
    @AppStorage(AppConstants.StorageKeys.dailyPlanOpenedDate) private var dailyPlanOpenedDate = ""
    @State private var homeSectionMode = HomeSectionMode.today.rawValue
    @State private var showNewcomerGuide = true

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.adaptive(colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Premium Hero (Merged Header, Pulse, Solar Term)
                        HomePremiumHero(
                            greeting: viewModel.greeting,
                            userName: viewModel.userName,
                            dateText: viewModel.currentDateString,
                            completed: taskCoordinator.wellnessProgress.completedTasks,
                            total: taskCoordinator.wellnessProgress.totalTasks,
                            solarTerm: viewModel.solarTerm,
                            careStatus: viewModel.careStatus,
                            onSolarTermTap: { viewModel.showSolarTermDetail = true }
                        )
                        .padding(.horizontal)

                        if showNewcomerGuide {
                            NewcomerGuideSection(onTaskTap: { taskId in
                                handleNewcomerTaskTap(taskId)
                            })
                            .padding(.horizontal)
                        }

                        sectionToggle
                            .padding(.horizontal)

                        if selectedSection == .today {
                            VStack(spacing: 24) {
                                // 2. Smart Insight Hub (Merged Plan, Nudge, Companion)
                                SmartInsightHub(
                                    viewModel: viewModel,
                                    completed: taskCoordinator.wellnessProgress.completedTasks,
                                    total: taskCoordinator.wellnessProgress.totalTasks,
                                    nudgeTitle: returnNudgeContent?.title,
                                    nudgeMessage: returnNudgeContent?.message,
                                    onNudgeAction: {
                                        if let nudge = returnNudgeContent {
                                            handleNudgeAction(nudge.primaryAction)
                                        }
                                    },
                                    onOpenPlan: { showDailyPlan = true }
                                )
                                .padding(.horizontal)

                                // 3. Health Toolbox Grid (Merged Quick Actions)
                                HealthToolboxGrid(actions: homeQuickActions)
                                    .padding(.horizontal)

                                // 4. Rituals Strip
                                if !viewModel.dailyRituals.isEmpty {
                                    DailyRitualStrip(rituals: viewModel.dailyRituals)
                                        .padding(.horizontal)
                                }

                                // 5. Goal/Challenge Card
                                MicroHabitChallengeCard()
                                    .padding(.horizontal)
                            }
                            .accessibilityIdentifier("HomeSectionToday")
                        } else {
                            VStack(spacing: 24) {
                                // 🎯 精选内容轮播
                                FeaturedCarouselSection()
                                    .padding(.horizontal)
                                    .accessibilityIdentifier("FeaturedCarouselSection")
                                
                                // 🎯 核心数据：融合养生指数卡片
                                IntegratedWellnessScoreCard(
                                    recordService: recordService,
                                    modernHealthService: modernHealthService
                                )
                                .padding(.horizontal)

                                // 🎯 节气文化（综合诗词+三候）
                                if let solarTerm = viewModel.solarTerm {
                                    SolarTermCultureCard(solarTerm: solarTerm)
                                        .padding(.horizontal)
                                }
                                
                                // 🎯 今日美食推荐
                                TodayRecommendationSection(
                                    recipes: viewModel.todayRecipes,
                                    themeColor: viewModel.solarTerm?.themeColor ?? .shunshiPrimary
                                )
                                .padding(.horizontal)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("HomeSectionExplore")
                        }
                        
                        Spacer(minLength: AppSize.tabBarHeight + 40)
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear {
                    loadHomeSectionMode()
                }
                .overlay(alignment: .topLeading) {
                    if isUITesting {
                        uiTestSectionToggleOverlay
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.showSolarTermDetail) {
                if let solarTerm = viewModel.solarTerm {
                    SolarTermDetailView(solarTerm: solarTerm)
                }
            }
            .navigationDestination(isPresented: $showConsultant) {
                ConsultantView()
            }
            .sheet(isPresented: $showObservation) {
                ObservationFlowView()
            }
            .sheet(isPresented: $showDailyPlan) {
                DailyPlanSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showBreathing) {
                QuickBreathingView()
            }
            .sheet(isPresented: $showHabitCheckin) {
                HabitCheckinView(careStatus: viewModel.careStatus)
            }
            .fullScreenCover(isPresented: $showConstitutionTest) {
                AIConstitutionTestView(solarTermName: appState.currentSolarTerm?.name ?? "当下")
            }

        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(error: $viewModel.error) {
            Task { await viewModel.loadData() }
        }
        .task {
            await viewModel.loadData()
            Task { await viewModel.generateDailyPlan(force: false) }
            challengeService.startIfNeeded()
            checkNewcomerGuideStatus()
        }
        .onChange(of: showDailyPlan) { _, isPresented in
            if isPresented {
                dailyPlanOpenedDate = todayKey
            }
        }
    }

    // MARK: - Daily Companion Section
    private var dailyCompanionSection: some View {
        HomeDailyCompanionCard(
            message: viewModel.dailyCompanionMessage,
            actionTitle: viewModel.dailyCompanionActionTitle,
            tags: viewModel.dailyCompanionTags,
            isRefreshing: viewModel.isGeneratingCompanion,
            onAction: {
                showDailyPlan = true
            },
            onRefresh: {
                Task { await viewModel.generateDailyCompanion(force: true) }
            }
        )
    }

    private var uiTestSectionToggleOverlay: some View {
        HStack(spacing: 12) {
            Button("今日") { updateHomeSectionMode(.today) }
                .accessibilityIdentifier("HomeSectionToggle_today")

            Button("探索") { updateHomeSectionMode(.explore) }
                .accessibilityIdentifier("HomeSectionToggle_explore")

            Text("mode:\(homeSectionMode)")
                .font(.system(size: 12))
                .opacity(0.15)
                .accessibilityIdentifier("HomeSectionModeValue")
                .accessibilityHidden(false)
        }
        .font(.system(size: 12))
        .padding(6)
        .opacity(0.15)
        .accessibilityHidden(false)
    }

    private var sectionToggle: some View {
        HStack(spacing: 8) {
            sectionToggleButton(for: .today)
            sectionToggleButton(for: .explore)
        }
        .padding(6)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(Capsule())
        .accessibilityIdentifier("HomeSectionToggle")
    }

    private func sectionToggleButton(for mode: HomeSectionMode) -> some View {
        let isSelected = selectedSection == mode
        return Button(action: { updateHomeSectionMode(mode) }) {
            Text(mode.title)
                .font(AppTypography.label(13))
                .foregroundColor(isSelected ? .white : Color.AppText.primary(colorScheme))
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.shunshiPrimary : Color.clear)
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(mode.title))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("HomeSectionToggle_\(mode.rawValue)")
    }

    private func updateHomeSectionMode(_ mode: HomeSectionMode) {
        homeSectionMode = mode.rawValue
        UserDefaults.standard.set(mode.rawValue, forKey: "home_section_mode")
    }

    private func loadHomeSectionMode() {
        if let stored = UserDefaults.standard.string(forKey: "home_section_mode"),
           HomeSectionMode(rawValue: stored) != nil {
            homeSectionMode = stored
        }
    }

    private var selectedSection: HomeSectionMode {
        HomeSectionMode(rawValue: homeSectionMode) ?? .today
    }

    private var homeQuickActions: [HomeQuickAction] {
        [
            HomeQuickAction(
                title: "今日记录",
                subtitle: "养生打卡",
                icon: "checkmark.seal.fill",
                color: .shunshiPrimary,
                destination: AnyView(JournalView())
            ),
            HomeQuickAction(
                title: "咨询小师",
                subtitle: "生活建议",
                icon: "bubble.left.and.bubble.right.fill",
                color: .seasonSummer,
                destination: AnyView(ConsultantView())
            ),
            HomeQuickAction(
                title: "节气日历",
                subtitle: "今日节气",
                icon: "calendar",
                color: .seasonAutumn,
                destination: AnyView(SolarTermHomeView())
            ),
            HomeQuickAction(
                title: "成长罗盘",
                subtitle: "节律画像",
                icon: "compass.drawing",
                color: .seasonWinter,
                destination: AnyView(GrowthCompassView())
            ),
            HomeQuickAction(
                title: "养生库",
                subtitle: "五维指南",
                icon: "leaf.fill",
                color: .seasonSpring,
                destination: AnyView(WellnessView())
            )
        ]
    }

    // MARK: - Return Nudge
    private enum ReturnNudgeAction {
        case openPlan
        case breathing
        case habitCheckin
    }

    private enum HomeSectionMode: String, CaseIterable {
        case today
        case explore

        var title: String {
            switch self {
            case .today: return "今日"
            case .explore: return "探索"
            }
        }
    }

    private struct ReturnNudgeContent {
        let title: String
        let message: String
        let primaryTitle: String
        let secondaryTitle: String?
        let icon: String
        let accent: Color
        let primaryAction: ReturnNudgeAction
        let secondaryAction: ReturnNudgeAction?
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    private var returnNudgeContent: ReturnNudgeContent? {
        let timeOfDay = AIAgentService.TimeOfDay.current
        let planOpenedToday = dailyPlanOpenedDate == todayKey
        let completed = taskCoordinator.wellnessProgress.completedTasks

        if !planOpenedToday && timeOfDay != .morning {
            return ReturnNudgeContent(
                title: "还没看今日计划",
                message: "用 2 分钟看一眼今日重点，能更安心地安排节奏。",
                primaryTitle: "打开计划",
                secondaryTitle: "先做呼吸",
                icon: "list.bullet.rectangle",
                accent: .shunshiPrimary,
                primaryAction: .openPlan,
                secondaryAction: .breathing
            )
        }

        if completed == 0 && (timeOfDay == .afternoon || timeOfDay == .evening || timeOfDay == .night) {
            return ReturnNudgeContent(
                title: "今天还没开始",
                message: "先做一个小动作就算开始，别给自己压力。",
                primaryTitle: "2分钟呼吸",
                secondaryTitle: "查看计划",
                icon: "wind",
                accent: SeasonalColors.currentSeasonPrimary,
                primaryAction: .breathing,
                secondaryAction: .openPlan
            )
        }

        if !challengeService.isCompletedToday && !challengeService.isCycleCompleted && !challengeService.isCycleExpired {
            return ReturnNudgeContent(
                title: "微习惯挑战提醒",
                message: "完成任意一个小习惯即可续火，今天还差一步。",
                primaryTitle: "去打卡",
                secondaryTitle: "查看计划",
                icon: "flame.fill",
                accent: .orange,
                primaryAction: .habitCheckin,
                secondaryAction: .openPlan
            )
        }

        return nil
    }

    private func handleNudgeAction(_ action: ReturnNudgeAction) {
        switch action {
        case .openPlan:
            showDailyPlan = true
        case .breathing:
            showBreathing = true
        case .habitCheckin:
            showHabitCheckin = true
        }
    }

    private func handleNewcomerTaskTap(_ taskId: Int) {
        switch taskId {
        case 1:
            showConstitutionTest = true
        case 2:
            showConsultant = true
        case 3:
            appState.selectedTab = .journal
        default:
            break
        }
    }

    private func checkNewcomerGuideStatus() {
        let hasCompletedConstitution = UserDefaults.standard.bool(forKey: "user_has_constitution")
        let hasTalkedToAI = UserDefaults.standard.integer(forKey: "ai_chat_count") > 0
        let hasRecord = UserDefaults.standard.integer(forKey: "wellness_record_count") > 0
        
        showNewcomerGuide = !(hasCompletedConstitution && hasTalkedToAI && hasRecord)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateService.shared)
        .preferredColorScheme(.dark)
}
