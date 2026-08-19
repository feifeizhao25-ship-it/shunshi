import SwiftUI

// MARK: - Solar Term Home View
/// 节气养生首页 - 展示当前节气、倒计时、每日重点等内容
struct SolarTermHomeView: View {
    @StateObject private var viewModel = SolarTermHomeViewModel()
    @EnvironmentObject var appState: AppStateService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    // 当前节气卡片
                    currentTermCard
                    
                    // 倒计时卡片
                    countdownCard
                    
                    // 每日一重点
                    dailyFocusCard
                    
                    // 节气养生任务
                    tasksSection
                    
                    // 快捷入口
                    quickActionsSection
                    
                    // 节气文化
                    cultureSection
                }
                .padding(.vertical, Spacing.section)
            }
            .background(
                ZStack {
                    AppBackground.light
                    
                    Circle()
                        .fill(Color.shunshiPrimary.opacity(0.12))
                        .frame(width: 500, height: 500)
                        .offset(x: -200, y: -250)
                        .blur(radius: 100)
                    
                    Circle()
                        .fill(SeasonalColors.currentSeasonPrimary.opacity(0.08))
                        .frame(width: 400, height: 400)
                        .offset(x: 200, y: 300)
                        .blur(radius: 80)
                }
                .ignoresSafeArea()
            )
            .navigationTitle("节气养生")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCalendar) {
                SolarTermCalendarView { term in
                    viewModel.selectTerm(term)
                }
            }
        }
    }
    
    // MARK: - 当前节气卡片
    private var currentTermCard: some View {
        VStack(spacing: Spacing.medium) {
            // 节气emoji和名称
            HStack(spacing: Spacing.small) {
                Text(viewModel.currentTerm.emoji)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentTerm.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppText.primary)
                    
                    Text(viewModel.currentTerm.description)
                        .font(.subheadline)
                        .foregroundColor(AppText.secondary)
                }
                
                Spacer()
            }
            
            // 进度条
            VStack(spacing: 4) {
                HStack {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                    Spacer()
                    Text("\(15 - viewModel.daysInTerm)天")
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
        }
        .padding(Spacing.card)
        .lumeGlass(cornerRadius: CornerRadius.card, blur: 20, opacity: 0.1)
        .padding(.horizontal, Spacing.page)
    }
    
    // MARK: - 倒计时卡片
    private var countdownCard: some View {
        Button {
            viewModel.showPreview = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("下一个节气")
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                    
                    HStack(spacing: 4) {
                        Text(viewModel.nextTerm?.emoji ?? "🌱")
                            .font(.system(size: 24))
                        Text(viewModel.nextTerm?.name ?? "立春")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppText.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.daysUntilNext)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(SeasonalColors.currentSeasonPrimary)
                    
                    Text("天后")
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                }
            }
            .padding(Spacing.card)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(AppBackground.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(SeasonalColors.currentSeasonPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, Spacing.page)
        .sheet(isPresented: $viewModel.showPreview) {
            SolarTermPreviewView(term: viewModel.nextTerm?.name ?? "立春")
        }
    }
    
    // MARK: - 每日一重点
    private var dailyFocusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("今日养生重点")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            HStack(spacing: Spacing.medium) {
                // 重点图标
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(SeasonalColors.currentSeasonPrimary.opacity(0.1))
                    )
                
                // 重点内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.dailyFocus)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(AppText.primary)
                    
                    Text("坚持7天，养出好习惯")
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                }
                
                Spacer()
                
                // 打卡按钮
                Button {
                    viewModel.completeFocus()
                } label: {
                    Image(systemName: viewModel.isFocusCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(viewModel.isFocusCompleted ? .green : AppText.tertiary)
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
        .padding(.horizontal, Spacing.page)
    }
    
    // MARK: - 养生任务
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("节气养生任务")
                    .font(.headline)
                    .foregroundColor(AppText.primary)
                
                Spacer()
                
                Text("\(viewModel.completedTasks)/\(viewModel.tasks.count)")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            
            LazyVStack(spacing: Spacing.small) {
                ForEach(viewModel.tasks) { task in
                    SolarTermTaskRow(task: task) {
                        viewModel.toggleTask(task)
                    }
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
        .padding(.horizontal, Spacing.page)
    }
    
    // MARK: - 快捷入口
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("快捷入口")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.small) {
                SolarTermQuickActionButton(
                    icon: "cup.and.saucer.fill",
                    title: "今日茶饮",
                    color: .orange
                ) {
                    viewModel.showTeaRecommendation = true
                }
                
                SolarTermQuickActionButton(
                    icon: "fork.knife",
                    title: "节气食谱",
                    color: .red
                ) {
                    viewModel.showRecipes = true
                }
                
                SolarTermQuickActionButton(
                    icon: "figure.walk",
                    title: "运动功法",
                    color: .green
                ) {
                    viewModel.showExercise = true
                }
                
                SolarTermQuickActionButton(
                    icon: "hand.point.up.left.fill",
                    title: "穴位保健",
                    color: .blue
                ) {
                    viewModel.showAcupoints = true
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
        .padding(.horizontal, Spacing.page)
        .sheet(isPresented: $viewModel.showTeaRecommendation) {
            TeaRecommendationView(term: viewModel.currentTerm.name)
        }
    }
    
    // MARK: - 节气文化
    private var cultureSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("节气文化")
                    .font(.headline)
                    .foregroundColor(AppText.primary)
                
                Spacer()
                
                Button("更多") {
                    viewModel.showCultureDetail = true
                }
                .font(.caption)
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    // 诗词卡片
                    CultureCard(
                        icon: "text.quote",
                        title: "节气诗词",
                        subtitle: viewModel.poetry.first?.title ?? "点击查看"
                    ) {
                        viewModel.showPoetry = true
                    }
                    
                    // 习俗卡片
                    CultureCard(
                        icon: "calendar.badge.clock",
                        title: "节气习俗",
                        subtitle: viewModel.customs.first?.title ?? "点击查看"
                    ) {
                        viewModel.showCustoms = true
                    }
                    
                    // 分享海报
                    CultureCard(
                        icon: "square.and.arrow.up",
                        title: "分享海报",
                        subtitle: "一键生成"
                    ) {
                        viewModel.showPosterGenerator = true
                    }
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
        .padding(.horizontal, Spacing.page)
        .sheet(isPresented: $viewModel.showCultureDetail) {
            CultureDetailView(term: viewModel.currentTerm.name, poetry: viewModel.poetry, customs: viewModel.customs)
        }
        .sheet(isPresented: $viewModel.showPoetry) {
            PoetryDetailView(poetry: viewModel.poetry)
        }
        .sheet(isPresented: $viewModel.showCustoms) {
            CustomsDetailView(customs: viewModel.customs)
        }
        .sheet(isPresented: $viewModel.showPosterGenerator) {
            PosterGeneratorView(term: viewModel.currentTerm)
        }
    }
}

// MARK: - Task Row
struct SolarTermTaskRow: View {
    let task: ServiceDailyTask
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : AppText.tertiary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(AppText.primary)
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(AppText.tertiary)
                }
                
                Spacer()
                
                Text("+\(task.points)")
                    .font(.caption)
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
            }
            .padding(.vertical, Spacing.small)
        }
    }
}

// MARK: - Quick Action Button
struct SolarTermQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.small) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .fill(color.opacity(0.1))
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppText.primary)
            }
        }
    }
}

// MARK: - Culture Card
struct CultureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppText.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            .padding(Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(AppBackground.cardLight)
            )
        }
    }
}

// MARK: - View Model
class SolarTermHomeViewModel: ObservableObject {
    @Published var currentTerm: SimpleSolarTerm
    @Published var nextTerm: SimpleSolarTerm?
    @Published var daysUntilNext: Int = 0
    @Published var daysInTerm: Int = 0
    @Published var progress: Double = 0.5
    @Published var dailyFocus: String = ""
    @Published var isFocusCompleted: Bool = false
    @Published var tasks: [ServiceDailyTask] = []
    @Published var completedTasks: Int = 0
    @Published var poetry: [Poetry] = []
    @Published var customs: [Custom] = []
    
    // UI状态
    @Published var showCalendar = false
    @Published var showPreview = false
    @Published var showTeaRecommendation = false
    @Published var showRecipes = false
    @Published var showExercise = false
    @Published var showAcupoints = false
    @Published var showCultureDetail = false
    @Published var showPosterGenerator = false
    @Published var showPoetry = false
    @Published var showCustoms = false
    
    init() {
        let service = SolarTermService.shared
        currentTerm = service.currentSolarTerm
        nextTerm = service.nextSolarTerm
        daysUntilNext = service.daysUntilNext
        dailyFocus = service.dailyFocus
        progress = service.solarTermProgress
        
        loadContent()
    }
    
    func selectTerm(_ term: SimpleSolarTerm) {
        currentTerm = term
        loadContent()
    }
    
    private func loadContent() {
        let service = SolarTermService.shared
        let content = service.getContent(for: currentTerm.name)
        tasks = content.dailyTasks
        poetry = content.poetry
        customs = content.customs
        completedTasks = tasks.filter { $0.isCompleted }.count
    }
    
    func toggleTask(_ task: ServiceDailyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            completedTasks = tasks.filter { $0.isCompleted }.count
        }
    }
    
    func completeFocus() {
        isFocusCompleted = true
    }
}

// MARK: - Solar Term Preview View
struct SolarTermPreviewView: View {
    let term: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.section) {
                // 节气信息
                VStack(spacing: Spacing.medium) {
                    Text("❄️")
                        .font(.system(size: 80))
                    
                    Text(term)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, Spacing.xlarge)
                
                // 预览内容
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("养生要点")
                        .font(.headline)
                    
                    Text(getPreviewContent(for: term))
                        .font(.body)
                        .foregroundColor(AppText.secondary)
                }
                .padding(Spacing.card)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(AppBackground.card)
                )
                .padding(.horizontal, Spacing.page)
                
                Spacer()
                
                Button("查看详情") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.buttonVertical)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .fill(SeasonalColors.currentSeasonPrimary)
                )
                .padding(.horizontal, Spacing.page)
                .padding(.bottom, Spacing.xlarge)
            }
            .background(AppBackground.light)
            .navigationTitle("节气预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getPreviewContent(for term: String) -> String {
        let previews: [String: String] = [
            "小雪": "小雪时节，宜温补养藏。建议早睡晚起，适当进补羊肉、桂圆等温性食物，注意保暖防寒。",
            "立冬": "立冬万物收藏，宜养肾藏阳。饮食以温补为主，可适当食用羊肉、生姜等，注意早睡晚起。",
            "冬至": "冬至一阳生，宜养肾护阳。可食用饺子、汤圆等传统食物，注意保暖，适当进补。"
        ]
        return previews[term] ?? "\(term)时节，顺应天时，调整作息，合理饮食。"
    }
}

// MARK: - Tea Recommendation View
struct TeaRecommendationView: View {
    let term: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.section) {
                // 茶饮信息
                VStack(spacing: Spacing.medium) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("红枣桂圆茶")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("适合\(term)时节饮用")
                        .font(.subheadline)
                        .foregroundColor(AppText.secondary)
                }
                .padding(.top, Spacing.xlarge)
                
                // 详情
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    DetailSection(title: "食材", items: ["红枣5颗", "桂圆10颗", "枸杞少量", "红糖适量"])
                    
                    DetailSection(title: "功效", items: ["补气养血", "温暖身心", "改善睡眠"])
                    
                    DetailSection(title: "冲泡方法", items: ["所有食材洗净", "放入杯中", "加入热水焖5分钟"])
                }
                .padding(Spacing.card)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(AppBackground.card)
                )
                .padding(.horizontal, Spacing.page)
                
                Spacer()
            }
            .background(AppBackground.light)
            .navigationTitle("节气茶饮")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppText.primary)
            
            ForEach(items, id: \.self) { item in
                HStack(spacing: Spacing.small) {
                    Circle()
                        .fill(SeasonalColors.currentSeasonPrimary)
                        .frame(width: 6, height: 6)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(AppText.secondary)
                }
            }
        }
    }
}

// MARK: - Solar Term Calendar View
struct SolarTermCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: ((SimpleSolarTerm) -> Void)?
    
    private let terms = SolarTermService.shared.solarTerms
    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 16)]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(terms, id: \.name) { term in
                        Button {
                            onSelect?(term)
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Text(term.emoji)
                                    .font(.system(size: 40))
                                Text(term.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppText.primary)
                                Text("\(term.startMonth)月\(term.startDay)日")
                                    .font(.caption2)
                                    .foregroundColor(AppText.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.card)
                                    .fill(AppBackground.card)
                            )
                        }
                    }
                }
                .padding()
            }
            .background(AppBackground.light)
            .navigationTitle("二十四节气")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Culture Detail View
struct CultureDetailView: View {
    let term: String
    let poetry: [Poetry]
    let customs: [Custom]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    // 诗词部分
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Label("节气诗词", systemImage: "text.quote")
                            .font(.headline)
                            .foregroundColor(SeasonalColors.currentSeasonPrimary)
                        
                        ForEach(poetry) { poem in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poem.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(poem.content)
                                    .font(.body)
                                    .foregroundColor(AppText.secondary)
                                Text("\(poem.dynasty)·\(poem.author)")
                                    .font(.caption)
                                    .foregroundColor(AppText.tertiary)
                            }
                            .padding(Spacing.card)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.card)
                                    .fill(AppBackground.card)
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.page)
                    
                    // 习俗部分
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Label("节气习俗", systemImage: "calendar.badge.clock")
                            .font(.headline)
                            .foregroundColor(SeasonalColors.currentSeasonPrimary)
                        
                        ForEach(customs) { custom in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(custom.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(custom.description)
                                    .font(.body)
                                    .foregroundColor(AppText.secondary)
                            }
                            .padding(Spacing.card)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.card)
                                    .fill(AppBackground.card)
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.page)
                }
                .padding(.vertical, Spacing.section)
            }
            .background(AppBackground.light)
            .navigationTitle("\(term)文化")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Poetry Detail View
struct PoetryDetailView: View {
    let poetry: [Poetry]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    ForEach(poetry) { poem in
                        VStack(spacing: Spacing.small) {
                            Text(poem.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(poem.dynasty)·\(poem.author)")
                                .font(.subheadline)
                                .foregroundColor(AppText.secondary)
                            
                            Text(poem.content)
                                .font(.title3)
                                .foregroundColor(AppText.primary)
                                .multilineTextAlignment(.center)
                                .padding(.top, Spacing.medium)
                        }
                        .padding(Spacing.xlarge)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .fill(AppBackground.card)
                        )
                    }
                }
                .padding(Spacing.page)
            }
            .background(AppBackground.light)
            .navigationTitle("节气诗词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Customs Detail View
struct CustomsDetailView: View {
    let customs: [Custom]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    ForEach(customs) { custom in
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Label(custom.title, systemImage: "calendar.badge.checkmark")
                                .font(.headline)
                                .foregroundColor(SeasonalColors.currentSeasonPrimary)
                            
                            Text(custom.description)
                                .font(.body)
                                .foregroundColor(AppText.secondary)
                        }
                        .padding(Spacing.card)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .fill(AppBackground.card)
                        )
                    }
                }
                .padding(Spacing.page)
            }
            .background(AppBackground.light)
            .navigationTitle("节气习俗")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Poster Generator View
struct PosterGeneratorView: View {
    let term: SimpleSolarTerm
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var selectedBlessing = "节气安康"
    
    private let blessings = ["节气安康", "顺应天时", "身心和谐", "养生有道", "福寿安康"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    // 预览
                    VStack(spacing: Spacing.medium) {
                        Text(term.emoji)
                            .font(.system(size: 80))
                        
                        Text(term.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(term.description)
                            .font(.subheadline)
                            .foregroundColor(AppText.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.xlarge)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(
                                LinearGradient(
                                    colors: [SeasonalColors.currentSeasonPrimary.opacity(0.2), AppBackground.card],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .padding(.horizontal, Spacing.page)
                    
                    // 输入表单
                    VStack(spacing: Spacing.medium) {
                        // 名字输入
                        VStack(alignment: .leading, spacing: 4) {
                            Text("您的名字")
                                .font(.subheadline)
                                .foregroundColor(AppText.primary)
                            
                            TextField("请输入名字", text: $userName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // 祝福语选择
                        VStack(alignment: .leading, spacing: 4) {
                            Text("祝福语")
                                .font(.subheadline)
                                .foregroundColor(AppText.primary)
                            
                            Picker("祝福语", selection: $selectedBlessing) {
                                ForEach(blessings, id: \.self) { blessing in
                                    Text(blessing).tag(blessing)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(Spacing.card)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(AppBackground.card)
                    )
                    .padding(.horizontal, Spacing.page)
                    
                    // 生成按钮
                    Button {
                        // TODO: 实现海报生成
                    } label: {
                        Label("生成海报", systemImage: "square.and.arrow.up")
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
                }
                .padding(.vertical, Spacing.section)
            }
            .background(AppBackground.light)
            .navigationTitle("分享海报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Solar Term Home") {
    SolarTermHomeView()
        .environmentObject(AppStateService.shared)
}
