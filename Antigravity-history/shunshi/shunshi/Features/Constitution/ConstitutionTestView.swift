import SwiftUI

// MARK: - Constitution Test View
/// 体质测试入口和流程视图
struct ConstitutionTestView: View {
    @StateObject private var viewModel = ConstitutionTestViewModel()
    @EnvironmentObject var appState: AppStateService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    // 测试介绍
                    testIntroSection
                    
                    // 测试版本选择
                    testVersionSelection
                    
                    // 现有体质卡片
                    if viewModel.hasExistingResult {
                        existingResultCard
                    }
                }
                .padding(.vertical, Spacing.section)
            }
            .background(AppBackground.light)
            .navigationTitle("体质辨识")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $viewModel.showTest) {
                ConstitutionTestProcessView(mode: viewModel.selectedMode)
            }
        }
    }
    
    // MARK: - 测试介绍
    private var testIntroSection: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
            
            Text("发现你的养生密码")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppText.primary)
            
            Text("基于《中医体质分类与判定》国家标准，通过科学的体质测评，了解您的体质特点，获取个性化的养生建议。")
                .font(.body)
                .foregroundColor(AppText.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.page)
            
            // 免责声明
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppText.tertiary)
                Text("本测试仅供日常养生参考，不能替代医学诊断。如有不适，请及时就医。")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            .padding(Spacing.card)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(AppBackground.cardLight)
            )
            .padding(.horizontal, Spacing.page)
        }
    }
    
    // MARK: - 测试版本选择
    private var testVersionSelection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("选择测试版本")
                .font(.headline)
                .foregroundColor(AppText.primary)
                .padding(.horizontal, Spacing.page)
            
            VStack(spacing: Spacing.small) {
                TestVersionCard(
                    version: "quick",
                    title: "快速版",
                    subtitle: "2分钟",
                    questionCount: 10,
                    description: "快速了解体质倾向",
                    isSelected: viewModel.selectedMode == .quick,
                    onSelect: { viewModel.selectedMode = .quick }
                )
                
                TestVersionCard(
                    version: "standard",
                    title: "标准版",
                    subtitle: "5分钟",
                    questionCount: 25,
                    description: "获得准确的体质判定",
                    isSelected: viewModel.selectedMode == .standard,
                    onSelect: { viewModel.selectedMode = .standard }
                )
                
                TestVersionCard(
                    version: "deep",
                    title: "深度版",
                    subtitle: "10分钟",
                    questionCount: 40,
                    description: "获得详细分析（付费）",
                    isSelected: viewModel.selectedMode == .deep,
                    onSelect: { viewModel.selectedMode = .deep },
                    isPremium: true
                )
            }
            .padding(.horizontal, Spacing.page)
            
            // 开始测试按钮
            Button {
                viewModel.showTest = true
            } label: {
                Text("开始测试")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.buttonVertical)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .fill(SeasonalColors.currentSeasonPrimary)
                    )
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.small)
        }
    }
    
    // MARK: - 现有结果卡片
    private var existingResultCard: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("您的体质档案")
                    .font(.headline)
                    .foregroundColor(AppText.primary)
                
                Spacer()
                
                Button("查看详情") {
                    viewModel.showProfile = true
                }
                .font(.caption)
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
            }
            .padding(.horizontal, Spacing.page)
            
            if let result = viewModel.existingResult {
                HStack(spacing: Spacing.medium) {
                    // 体质emoji
                    Text(result.primaryConstitution.emoji)
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.primaryConstitution.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppText.primary)
                        
                        Text("平和度：\(Int(result.pingheScore))%")
                            .font(.caption)
                            .foregroundColor(AppText.tertiary)
                        
                        // 下次复测提醒
                        if let nextDate = viewModel.nextTestDate {
                            Text("建议复测：\(nextDate)")
                                .font(.caption2)
                                .foregroundColor(SeasonalColors.currentSeasonPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    // 分享按钮
                    Button {
                        viewModel.shareResult()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(SeasonalColors.currentSeasonPrimary)
                    }
                }
                .padding(Spacing.card)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(AppBackground.card)
                )
                .padding(.horizontal, Spacing.page)
            }
        }
    }
}

// MARK: - Test Version Card
struct TestVersionCard: View {
    let version: String
    let title: String
    let subtitle: String
    let questionCount: Int
    let description: String
    let isSelected: Bool
    let onSelect: () -> Void
    var isPremium: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.medium) {
                // 选中状态指示
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? SeasonalColors.currentSeasonPrimary : AppText.tertiary)
                    .font(.title3)
                
                // 版本信息
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(AppText.primary)
                        
                        if isPremium {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    Text("\(questionCount)题 | 约\(subtitle)")
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                }
                
                Spacer()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            .padding(Spacing.card)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(isSelected 
                          ? SeasonalColors.currentSeasonPrimary.opacity(0.1) 
                          : AppBackground.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(isSelected 
                            ? SeasonalColors.currentSeasonPrimary 
                            : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Constitution Test Process View
struct ConstitutionTestProcessView: View {
    let mode: TestMode
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ConstitutionTestProcessViewModel
    
    init(mode: TestMode) {
        self.mode = mode
        self._viewModel = StateObject(wrappedValue: ConstitutionTestProcessViewModel(mode: mode))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground.light
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 进度条
                    progressSection
                    
                    if viewModel.isComplete {
                        // 测试完成显示结果
                        testCompleteSection
                    } else {
                        // 测试进行中
                        questionSection
                    }
                }
            }
            .navigationTitle("体质测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("退出") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 进度条
    private var progressSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(viewModel.currentIndex + 1)/\(viewModel.session.questions.count)")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
                Spacer()
                Text(mode == .quick ? "快速版" : mode == .standard ? "标准版" : "深度版")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppBackground.cardLight)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SeasonalColors.currentSeasonPrimary)
                        .frame(width: geometry.size.width * viewModel.progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(Spacing.card)
    }
    
    // MARK: - 题目区域
    private var questionSection: some View {
        VStack(spacing: Spacing.section) {
            // 题目
            Text(viewModel.currentQuestion?.text ?? "")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppText.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.page)
            
            Spacer()
            
            // 选项
            VStack(spacing: Spacing.small) {
                ForEach(viewModel.currentQuestion?.options ?? []) { option in
                    Button {
                        viewModel.selectAnswer(option.text)
                    } label: {
                        Text(option.text)
                            .font(.body)
                            .foregroundColor(viewModel.selectedAnswer == option.text ? .white : AppText.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.card)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .fill(viewModel.selectedAnswer == option.text 
                                          ? SeasonalColors.currentSeasonPrimary 
                                          : AppBackground.card)
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            
            Spacer()
            
            // 下一题按钮
            Button {
                viewModel.nextQuestion()
            } label: {
                Text(viewModel.isLastQuestion ? "查看结果" : "下一题")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.buttonVertical)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .fill(viewModel.selectedAnswer != nil 
                                  ? SeasonalColors.currentSeasonPrimary 
                                  : AppText.tertiary)
                    )
            }
            .disabled(viewModel.selectedAnswer == nil)
            .padding(.horizontal, Spacing.page)
            .padding(.bottom, Spacing.xlarge)
        }
    }
    
    // MARK: - 测试完成
    private var testCompleteSection: some View {
        VStack(spacing: Spacing.section) {
            Spacer()
            
            // 成功图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("测试完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppText.primary)
            
            Text("正在分析您的体质...")
                .font(.body)
                .foregroundColor(AppText.secondary)
            
            // 加载指示器
            ProgressView()
                .padding(.top, Spacing.small)
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.showResult()
            }
        }
    }
}

// MARK: - Test Process ViewModel
class ConstitutionTestProcessViewModel: ObservableObject {
    var session: TestSession
    @Published var currentIndex: Int = 0
    @Published var selectedAnswer: String?
    @Published var isComplete = false
    @Published var showResultView = false
    
    init(mode: TestMode) {
        self.session = ConstitutionService.shared.startTest(mode: mode, userId: "currentUser")
        self.currentIndex = 0
    }
    
    var progress: Double {
        session.progress
    }
    
    var currentQuestion: TestQuestion? {
        session.questions[safe: currentIndex]
    }
    
    var isLastQuestion: Bool {
        currentIndex == session.questions.count - 1
    }
    
    func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        if let question = currentQuestion {
            session.answers[question.id] = answer
        }
    }
    
    func nextQuestion() {
        guard selectedAnswer != nil else { return }
        
        if isLastQuestion {
            isComplete = true
        } else {
            currentIndex += 1
            selectedAnswer = nil
        }
    }
    
    func showResult() {
        showResultView = true
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Preview
#Preview("Constitution Test") {
    ConstitutionTestView()
        .environmentObject(AppStateService.shared)
}

#Preview("Test Process") {
    ConstitutionTestProcessView(mode: .quick)
}
