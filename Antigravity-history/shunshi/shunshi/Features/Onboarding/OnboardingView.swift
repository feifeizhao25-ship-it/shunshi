import SwiftUI
import CoreLocation

// MARK: - Onboarding View
/// 新用户引导页面 - 包含产品介绍和快速画像采集
struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0
    @State private var showQuickProfile = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "leaf.fill",
            title: "顺应时令",
            subtitle: "在大自然里养生",
            description: "春生夏长，秋收冬藏。小师带你听懂身体的换季信号。",
            highlights: ["每日气温与节气提醒", "简单易行的养生锦囊", "轻量生活记录"]
        ),
        OnboardingPage(
            imageName: "heart.text.square.fill",
            title: "全方位照顾",
            subtitle: "把健康变简单",
            description: "吃好每一餐，睡个安稳觉。让古人的智慧变成现代人的小习惯。",
            highlights: ["按季节定制食谱", "顺应时辰的作息建议", "办公室也能做的伸展"]
        ),
        OnboardingPage(
            imageName: "person.crop.circle.badge.checkmark",
            title: "测测身体性格",
            subtitle: "更懂你，才更有效",
            description: "每个人都是独特的，花2分钟了解自己的体质，告别盲目跟风。",
            highlights: ["简单有趣的测试", "生成你的专属标签", "定制化养生方案"]
        ),
        OnboardingPage(
            imageName: "bubble.left.and.bubble.right.fill",
            title: "你的顺时小师",
            subtitle: "懂节气，更懂你",
            description: "随时随地的健康顾问，不仅会聊天，更会贴心地关心你。",
            highlights: ["24小时在线解答", "给出具体的行动建议", "像老朋友一样的陪伴"]
        )
    ]
    
    var body: some View {
        ZStack {
            // Premium Background
            ZStack {
                AppBackground.light
                
                // Generative blob-like shapes
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .offset(x: -150, y: -250)
                    .blur(radius: 80)
                
                Circle()
                    .fill(Color.seasonSpring.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: 180, y: 300)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if showQuickProfile {
                    // 快速画像采集流程
                    QuickProfileView(isCompleted: $isCompleted, showOnboarding: $showQuickProfile)
                } else {
                    // 原有引导页
                    introductionContent
                }
            }
        }
    }
    
    // MARK: - 引导页内容
    private var introductionContent: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? SeasonalColors.currentSeasonPrimary : AppText.tertiary)
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Buttons
            VStack(spacing: 12) {
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation(.spring(response: 0.5)) {
                            currentPage += 1
                        }
                    } label: {
                        Text("下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(SeasonalColors.currentSeasonPrimary)
                            )
                    }
                    .accessibilityIdentifier("OnboardingNextButton")
                } else {
                    Button {
                        withAnimation(.spring(response: 0.5)) {
                            showQuickProfile = true
                        }
                    } label: {
                        Text("开启养生之旅")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(SeasonalColors.currentSeasonPrimary)
                            )
                    }
                    .accessibilityIdentifier("StartWellnessButton")
                }

                if currentPage < pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("跳过")
                            .font(.subheadline)
                            .foregroundColor(AppText.secondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.bottom, 32)

            Text("顺时提供养生建议，不替代医生或心理咨询。如有不适请及时就医，我们也不会频繁打扰你。")
                .font(.footnote)
                .foregroundColor(AppText.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.page + 12)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Page View
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Spacing.section) {
            Spacer()

            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SeasonalColors.currentSeasonPrimary, SeasonalColors.currentSeasonPrimaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: SeasonalColors.currentSeasonPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

            // Text content
            VStack(spacing: Spacing.small) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppText.primary)
                    .tracking(-0.5)

                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color.shunshiPrimary)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(AppText.secondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.page + 20)
            }

            // Highlight list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.highlights, id: \.self) { highlight in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SeasonalColors.currentSeasonPrimary)
                            .font(.caption)
                        Text(highlight)
                            .font(.subheadline)
                            .foregroundColor(AppText.primary)
                    }
                }
            }
            .padding(.horizontal, Spacing.page + 24)
            .padding(.vertical, Spacing.card)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(AppBackground.card)
            )

            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: AppConstants.StorageKeys.hasCompletedOnboarding)
        withAnimation(.spring()) {
            isCompleted = true
        }
        AnalyticsService.shared.trackEvent(.onboardingCompleted)
    }
}

// MARK: - Quick Profile View
/// 快速画像采集页面 - 30秒完成基础信息采集
struct QuickProfileView: View {
    @Binding var isCompleted: Bool
    @Binding var showOnboarding: Bool
    @State private var currentStep = 0
    @StateObject private var profileViewModel = QuickProfileViewModel()
    
    private let steps: [ProfileStep] = [
        ProfileStep(type: .feeling, title: "您此刻的感觉", subtitle: "顺时小师将根据您的状态即刻建议"),
        ProfileStep(type: .age, title: "您的年龄段", subtitle: "帮助我们提供更合适的建议"),
        ProfileStep(type: .gender, title: "您的性别", subtitle: "体质养生男女有别"),
        ProfileStep(type: .concerns, title: "您关注的问题", subtitle: "多选，最多3个"),
        ProfileStep(type: .insight, title: "智能养生洞察", subtitle: "顺时小师的初步建议"),
        ProfileStep(type: .constitution, title: "进阶体质辨识", subtitle: "2分钟完整测评")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            VStack(spacing: Spacing.small) {
                HStack(spacing: 4) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? SeasonalColors.currentSeasonPrimary : AppBackground.cardLight)
                            .frame(height: 4)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                Text("Step \(currentStep + 1)/\(steps.count)")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            .padding(.top, Spacing.xlarge)
            .padding(.horizontal, Spacing.page)
            
            // Step content
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    stepContent(steps[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Navigation buttons
            VStack(spacing: Spacing.small) {
                if currentStep < steps.count - 1 {
                    Button {
                        if profileViewModel.canProceed(from: steps[currentStep].type) {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    } label: {
                        Text("下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(profileViewModel.canProceed(from: steps[currentStep].type) 
                                          ? SeasonalColors.currentSeasonPrimary 
                                          : AppText.tertiary)
                            )
                    }
                    .disabled(!profileViewModel.canProceed(from: steps[currentStep].type))
                    
                    Button {
                        withAnimation {
                            currentStep += 1
                        }
                    } label: {
                        Text("跳过")
                            .font(.subheadline)
                            .foregroundColor(AppText.secondary)
                    }
                } else {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("开始养生之旅")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(SeasonalColors.currentSeasonPrimary)
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.bottom, 32)
        }
        .environmentObject(profileViewModel)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private func stepContent(_ step: ProfileStep) -> some View {
        VStack(spacing: Spacing.section) {
            // Title
            VStack(spacing: Spacing.small) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppText.primary)
                
                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppText.secondary)
            }
            .padding(.top, Spacing.xlarge)
            
            Spacer()
            
            // Content based on step type
            switch step.type {
            case .feeling:
                FeelingSelectionView(selectedFeeling: $profileViewModel.currentFeeling)
            case .age:
                AgeSelectionView(selectedAge: $profileViewModel.ageRange)
            case .gender:
                GenderSelectionView(selectedGender: $profileViewModel.gender)
            case .concerns:
                ConcernsSelectionView(selectedConcerns: $profileViewModel.concerns)
            case .insight:
                HealthInsightView(viewModel: profileViewModel)
            case .constitution:
                ConstitutionQuickTestView(viewModel: profileViewModel)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.page)
    }
    
    private func completeOnboarding() {
        // 保存用户画像
        profileViewModel.saveProfile()
        
        UserDefaults.standard.set(true, forKey: AppConstants.StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.set(true, forKey: "hasCompletedQuickProfile")
        
        withAnimation(.spring()) {
            isCompleted = true
        }
        AnalyticsService.shared.trackEvent(.onboardingCompleted)
        AnalyticsService.shared.trackEvent(.profileComplete)
    }
}

// MARK: - Profile Step
struct ProfileStep {
    let type: StepType
    let title: String
    let subtitle: String
    
    enum StepType {
        case feeling
        case age
        case gender
        case concerns
        case insight
        case constitution
    }
}

// MARK: - Health Insight View
struct HealthInsightView: View {
    @ObservedObject var viewModel: QuickProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: Spacing.xlarge) {
            // Animated AI Avatar
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundColor(.shunshiPrimary)
                    .symbolEffect(.bounce, options: .repeating)
            }
            
            VStack(spacing: Spacing.medium) {
                Text("顺时小师正在为您生成解读...")
                    .font(.subheadline)
                    .foregroundColor(AppText.secondary)
                
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    insightRow(icon: "calendar.badge.clock", text: "根据您的年龄，当前\(AppStateService.shared.currentSolarTerm?.name ?? "处暑")时节宜滋润防燥。")
                    insightRow(icon: "heart.text.square", text: "针对您关注的\(viewModel.concerns.first ?? "睡眠")问题，建议睡前按压涌泉穴。")
                    insightRow(icon: "leaf", text: "升级可解锁完整 21 天节气调理计划，先体验也可以。")
                }
                .padding(Spacing.card)
                .glassCard()
            }
        }
        .padding(.horizontal, Spacing.page)
    }
    
    private func insightRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: icon)
                .foregroundColor(.shunshiPrimary)
                .font(.body)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(AppText.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Quick Profile ViewModel
class QuickProfileViewModel: ObservableObject {
    @Published var currentFeeling: String?
    @Published var ageRange: String?
    @Published var gender: String?
    @Published var concerns: Set<String> = []
    @Published var hasCompletedConstitutionTest = false
    @Published var constitutionResult: String?
    
    private let maxConcerns = 3
    
    func canProceed(from stepType: ProfileStep.StepType) -> Bool {
        switch stepType {
        case .feeling:
            return currentFeeling != nil
        case .age:
            return ageRange != nil
        case .gender:
            return gender != nil
        case .concerns:
            return !concerns.isEmpty
        case .insight:
            return true // AI insight is informational
        case .constitution:
            return true // 可跳过
        }
    }
    
    func toggleConcern(_ concern: String) {
        if concerns.contains(concern) {
            concerns.remove(concern)
        } else if concerns.count < maxConcerns {
            concerns.insert(concern)
        }
    }
    
    func saveProfile() {
        // 保存到本地和服务器
        UserDefaults.standard.set(currentFeeling, forKey: "user_initial_feeling")
        UserDefaults.standard.set(ageRange, forKey: "user_age_range")
        UserDefaults.standard.set(gender, forKey: "user_gender")
        UserDefaults.standard.set(Array(concerns), forKey: "user_concerns")
        UserDefaults.standard.set(hasCompletedConstitutionTest, forKey: "user_has_constitution")
        if let result = constitutionResult {
            UserDefaults.standard.set(result, forKey: "user_constitution")
        }
        
        // 同步到分析服务
        let profile = UserProfile(
            userId: "",
            ageRange: ageRange,
            gender: gender,
            constitution: constitutionResult,
            city: nil,
            isVIP: false,
            memberDays: 0,
            registerDate: Date(),
            lastActiveDate: Date()
        )
        AnalyticsService.shared.setUserProfile(profile)
    }
}

// MARK: - Feeling Selection View
struct FeelingSelectionView: View {
    @Binding var selectedFeeling: String?
    
    private let feelings = [
        ("精神饱满", "能量满满，充满活力", "sparkles"),
        ("有些疲惫", "身体沉重，想休息", "battery.25"),
        ("手脚冰凉", "即使加衣也觉得冷", "thermometer.snowflake"),
        ("身体燥热", "手心发热，口干舌燥", "thermometer.sun.fill"),
        ("焦虑压力", "心绪不宁，难以入睡", "wind"),
        ("消化不良", "胃部胀满，食欲不佳", "stomach")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.medium) {
                ForEach(feelings, id: \.0) { feeling, desc, icon in
                    Button {
                        selectedFeeling = feeling
                    } label: {
                        VStack(spacing: Spacing.small) {
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(selectedFeeling == feeling ? .white : SeasonalColors.currentSeasonPrimary)
                            
                            Text(feeling)
                                .font(.headline)
                                .foregroundColor(selectedFeeling == feeling ? .white : AppText.primary)
                            
                            Text(desc)
                                .font(.caption2)
                                .foregroundColor(selectedFeeling == feeling ? .white.opacity(0.8) : AppText.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .padding(Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .fill(selectedFeeling == feeling 
                                      ? SeasonalColors.currentSeasonPrimary 
                                      : AppBackground.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(selectedFeeling == feeling 
                                        ? SeasonalColors.currentSeasonPrimary 
                                        : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, Spacing.medium)
        }
    }
}

// MARK: - Age Selection View
struct AgeSelectionView: View {
    @Binding var selectedAge: String?
    
    private let ageRanges = [
        ("18-25岁", "精力充沛"),
        ("26-35岁", "事业上升期"),
        ("36-45岁", "注重养生"),
        ("46-55岁", "调理身体"),
        ("56-65岁", "退休养生"),
        ("65岁以上", "安享晚年")
    ]
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            ForEach(ageRanges, id: \.0) { age, desc in
                Button {
                    selectedAge = age
                } label: {
                    HStack {
                        Text(age)
                            .font(.body)
                            .foregroundColor(AppText.primary)
                        
                        Spacer()
                        
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(AppText.tertiary)
                        
                        Image(systemName: selectedAge == age ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedAge == age ? SeasonalColors.currentSeasonPrimary : AppText.tertiary)
                            .font(.title3)
                    }
                    .padding(.horizontal, Spacing.card)
                    .padding(.vertical, Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(selectedAge == age 
                                  ? SeasonalColors.currentSeasonPrimary.opacity(0.1) 
                                  : AppBackground.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(selectedAge == age 
                                    ? SeasonalColors.currentSeasonPrimary 
                                    : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Gender Selection View
struct GenderSelectionView: View {
    @Binding var selectedGender: String?
    
    var body: some View {
        HStack(spacing: Spacing.card) {
            Button {
                selectedGender = "男"
            } label: {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedGender == "男" ? .white : SeasonalColors.currentSeasonPrimary)
                    
                    Text("男")
                        .font(.headline)
                        .foregroundColor(selectedGender == "男" ? .white : AppText.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xlarge)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(selectedGender == "男" 
                              ? SeasonalColors.currentSeasonPrimary 
                              : AppBackground.card)
                )
            }
            
            Button {
                selectedGender = "女"
            } label: {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedGender == "女" ? .white : SeasonalColors.currentSeasonPrimary)
                    
                    Text("女")
                        .font(.headline)
                        .foregroundColor(selectedGender == "女" ? .white : AppText.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xlarge)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(selectedGender == "女" 
                              ? SeasonalColors.currentSeasonPrimary 
                              : AppBackground.card)
                )
            }
        }
    }
}

// MARK: - Concerns Selection View
struct ConcernsSelectionView: View {
    @Binding var selectedConcerns: Set<String>
    @EnvironmentObject var viewModel: QuickProfileViewModel
    
    private let concerns = [
        ("睡眠质量", "sleep", "bed.circle"),
        ("容易疲劳", "fatigue", "bolt.circle"),
        ("肠胃问题", "stomach", "stomach.circle"),
        ("情绪管理", "emotion", "heart.circle"),
        ("皮肤状态", "skin", "face.smiling.circle"),
        ("减重塑形", "weight", "figure.walk.circle"),
        ("免疫力", "immunity", "shield.checkerboard"),
        ("精力不足", "energy", "battery.100")
    ]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.small) {
            ForEach(concerns, id: \.1) { name, key, icon in
                Button {
                    viewModel.toggleConcern(key)
                } label: {
                    VStack(spacing: Spacing.small) {
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(selectedConcerns.contains(key) 
                                             ? .white 
                                             : SeasonalColors.currentSeasonPrimary)
                        
                        Text(name)
                            .font(.subheadline)
                            .foregroundColor(selectedConcerns.contains(key) 
                                             ? .white 
                                             : AppText.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.card)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(selectedConcerns.contains(key) 
                                  ? SeasonalColors.currentSeasonPrimary 
                                  : AppBackground.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(selectedConcerns.contains(key) 
                                    ? SeasonalColors.currentSeasonPrimary 
                                    : AppText.tertiary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        
        // 已选计数
        Text("已选 \(selectedConcerns.count)/3")
            .font(.caption)
            .foregroundColor(AppText.tertiary)
            .padding(.top, Spacing.small)
    }
}

// MARK: - Constitution Quick Test View
struct ConstitutionQuickTestView: View {
    @ObservedObject var viewModel: QuickProfileViewModel
    @State private var currentQuestion = 0
    
    private let questions = [
        ("您容易疲乏吗？", ["经常", "偶尔", "很少"]),
        ("您容易气短吗？", ["经常", "偶尔", "很少"]),
        ("您容易心慌吗？", ["经常", "偶尔", "很少"]),
        ("您容易头晕吗？", ["经常", "偶尔", "很少"]),
        ("您比同龄人怕冷吗？", ["经常", "偶尔", "很少"])
    ]
    
    var body: some View {
        VStack(spacing: Spacing.section) {
            // 进度
            Text("\(currentQuestion + 1)/\(questions.count)")
                .font(.caption)
                .foregroundColor(AppText.tertiary)
            
            // 问题
            Text(questions[currentQuestion].0)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(AppText.primary)
                .multilineTextAlignment(.center)
            
            // 选项
            VStack(spacing: Spacing.small) {
                ForEach(questions[currentQuestion].1, id: \.self) { option in
                    Button {
                        // 记录答案（简化处理）
                    } label: {
                        Text(option)
                            .font(.body)
                            .foregroundColor(AppText.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(AppBackground.card)
                            )
                    }
                }
            }
            
            Spacer()
            
            // 按钮
            HStack(spacing: Spacing.card) {
                if currentQuestion > 0 {
                    Button("上一题") {
                        currentQuestion -= 1
                    }
                    .font(.subheadline)
                    .foregroundColor(AppText.secondary)
                }
                
                Spacer()
                
                if currentQuestion < questions.count - 1 {
                    Button("下一题") {
                        currentQuestion += 1
                    }
                    .font(.subheadline)
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
                } else {
                    Button("完成测评") {
                        viewModel.hasCompletedConstitutionTest = true
                        viewModel.constitutionResult = "气虚质" // 简化：假设结果
                    }
                    .font(.subheadline)
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
                }
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
    let description: String
    let highlights: [String]
}

// MARK: - Preview
#Preview("Onboarding") {
    OnboardingView(isCompleted: .constant(false))
}

#Preview("Quick Profile") {
    QuickProfileView(isCompleted: .constant(false), showOnboarding: .constant(true))
}
