import SwiftUI

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isFavorited: Bool = false
    @State private var selectedTab: DetailTab = .ingredients
    
    enum DetailTab: String, CaseIterable {
        case ingredients = "全食材"
        case steps = "做法"
        case tips = "秘诀"
    }
    
    /// 生成食谱的AI图片提示词
    private var imagePrompt: String {
        "Professional food photography of '\(recipe.name)'. Description: \(recipe.description). Traditional Chinese dish, elegant ceramic plate, warm lighting, appetizing presentation, high quality, 8k resolution"
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero Image
                heroSection
                
                // Content
                VStack(spacing: AppSpacing.lg) {
                    // Title & Meta
                    titleSection
                    
                    // Quick Info
                    quickInfoSection
                    
                    // Effects Tags
                    effectsSection
                    
                    // Tab Selector
                    tabSelector
                    
                    // Tab Content
                    tabContent
                    
                    // Constitution Suitability
                    constitutionSection
                    
                    // Source
                    if let source = recipe.source {
                        sourceSection(source)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl + AppSpacing.lg)
            }
        }
        .background(Color.Background.adaptive(colorScheme).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { isFavorited.toggle() }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : Color.AppText.muted(colorScheme))
                }
            }
        }
        .onAppear {
            isFavorited = recipe.isFavorited
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // AI Generated Image
            AIImageView(
                prompt: imagePrompt,
                cacheKey: "recipe_detail_\(recipe.id)",
                aspectRatio: 375/400
            )
            .frame(height: 360)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: Color.Background.adaptive(colorScheme).opacity(0.6), location: 0.8),
                    .init(color: Color.Background.adaptive(colorScheme), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating AI Scan Button
            Button(action: {
                // TODO: Start AI Ingredient Recognition
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 20))
                    Text("AI 食材识别")
                        .font(AppTypography.headline(14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .background(Color.shunshiPrimary.opacity(0.6))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 10)
            }
            .padding(.bottom, 20)
            
            // Top Badges
            VStack {
                HStack {
                    Text(recipe.category.displayName)
                        .font(AppTypography.caption(10).bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.shunshiPrimary)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if recipe.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                            Text("PRO")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    }
                }
                .padding(AppSpacing.lg)
                Spacer()
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(recipe.name)
                .font(AppTypography.solarTermTitle(28))
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            Text(recipe.description)
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -AppSpacing.xl)
    }
    
    // MARK: - Quick Info Section
    private var quickInfoSection: some View {
        HStack(spacing: 0) {
            QuickInfoItem(icon: "clock", value: recipe.cookingTimeText, label: "烹饪时间")
            
            Divider()
                .frame(height: 24)
                .background(Color.gray.opacity(0.2))
            
            QuickInfoItem(icon: "flame", value: recipe.difficulty.displayName, label: "难度")
            
            Divider()
                .frame(height: 24)
                .background(Color.gray.opacity(0.2))
            
            QuickInfoItem(icon: "person.2", value: "\(recipe.servings)人份", label: "份量")
            
            if let calories = recipe.calories {
                Divider()
                    .frame(height: 24)
                    .background(Color.gray.opacity(0.2))
                
                QuickInfoItem(icon: "bolt", value: "\(calories)", label: "卡路里")
            }
        }
        .padding(.vertical, AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Effects Section
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("功效")
                .font(AppTypography.sectionTitle())
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(recipe.effects, id: \.self) { effect in
                    Text(effect)
                        .font(AppTypography.caption())
                        .foregroundColor(.shunshiPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.shunshiPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(AppAnimation.fast) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: AppSpacing.sm) {
                        Text(tab.rawValue)
                            .font(selectedTab == tab ? AppTypography.headline(15) : AppTypography.body(15))
                            .foregroundColor(selectedTab == tab ? .shunshiPrimary : Color.AppText.muted(colorScheme))
                        
                        Rectangle()
                            .fill(Color.shunshiPrimary)
                            .frame(height: 2)
                            .opacity(selectedTab == tab ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, AppSpacing.md)
    }
    
    @State private var isShowingPaywall: Bool = false
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        if recipe.isPremium && (selectedTab == .steps || selectedTab == .tips) {
            premiumLockOverlay
        } else {
            switch selectedTab {
            case .ingredients:
                ingredientsList
            case .steps:
                stepsList
            case .tips:
                tipsList
            }
        }
    }
    
    // MARK: - Premium Lock Overlay
    private var premiumLockOverlay: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.shunshiPrimary)
            
            VStack(spacing: AppSpacing.xs) {
                Text("此内容为会员专享")
                    .font(AppTypography.headline(18))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text("订阅顺时高级会员，解锁所有养生秘方")
                    .font(AppTypography.caption())
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
            
            Button(action: { isShowingPaywall = true }) {
                Text("立即解锁")
                    .font(AppTypography.headline(16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.shunshiPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(Color.shunshiPrimary.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $isShowingPaywall) {
            NavigationStack {
                MembershipPricingView()
            }
        }
    }
    
    // MARK: - Ingredients List
    private var ingredientsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(sampleIngredients.indices, id: \.self) { index in
                HStack {
                    Text(sampleIngredients[index].name)
                        .font(AppTypography.body())
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    Spacer()
                    
                    Text(sampleIngredients[index].amount)
                        .font(AppTypography.body())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                .padding(.vertical, AppSpacing.sm)
                
                if index < sampleIngredients.count - 1 {
                    Divider()
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Steps List
    private var stepsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(sampleSteps.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    // Step number
                    Text("\(index + 1)")
                        .font(AppTypography.headline(14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.shunshiPrimary)
                        .clipShape(Circle())
                    
                    // Step content
                    Text(sampleSteps[index])
                        .font(AppTypography.body())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                        .lineSpacing(4)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Tips List
    private var tipsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(sampleTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                    
                    Text(tip)
                        .font(AppTypography.body())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                        .lineSpacing(4)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Constitution Section
    private var constitutionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("体质契合度")
                    .font(AppTypography.sectionTitle())
                Spacer()
                Text("AI 智能分析")
                    .font(AppTypography.caption(10))
                    .foregroundColor(.shunshiPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: AppSpacing.lg) {
                // Match Card
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.1), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: 0.95)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text("95%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("极度适合")
                        .font(AppTypography.caption(12).bold())
                        .foregroundColor(.green)
                }
                .padding(AppSpacing.md)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("为您推荐")
                        .font(AppTypography.headline(14))
                    
                    Text("本膳食富含温补食材，能有效改善\(recipe.suitableFor.first?.displayName ?? "身体")状态，特别适合在当前\(AppStateService.shared.currentSolarTerm?.name ?? "季节")食用。")
                        .font(AppTypography.caption(13))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Source Section
    private func sourceSection(_ source: RecipeSource) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let text = source.displayText {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "book.closed")
                        .foregroundColor(.shunshiPrimary)
                    
                    Text(text)
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Sample Data
    private var sampleIngredients: [(name: String, amount: String)] {
        [
            ("羊肉", "500克"),
            ("当归", "15克"),
            ("生姜", "30克"),
            ("料酒", "2勺"),
            ("盐", "适量"),
            ("葱段", "适量")
        ]
    }
    
    private var sampleSteps: [String] {
        [
            "羊肉洗净切块，冷水下锅，加入料酒，大火煮开后撇去浮沫，捞出备用。",
            "当归洗净，生姜切片备用。",
            "将焯好的羊肉放入砂锅，加入当归、生姜和足量清水。",
            "大火煮开后转小火，慢炖1.5-2小时。",
            "出锅前加盐调味，撒上葱花即可享用。"
        ]
    }
    
    private var sampleTips: [String] {
        [
            "羊肉要选用新鲜的带皮羊肉，肥瘦相间为佳。",
            "当归不要放太多，否则会有苦味。",
            "炖煮时间越长，汤越浓郁。",
            "此汤性温，阴虚火旺者慎食。"
        ]
    }
}

// MARK: - Quick Info Item
struct QuickInfoItem: View {
    let icon: String
    let value: String
    let label: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(.shunshiPrimary)
                .font(.system(size: 18))
            
            Text(value)
                .font(AppTypography.headline(14))
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            Text(label)
                .font(AppTypography.caption())
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RecipeDetailView(recipe: .preview)
    }
    .preferredColorScheme(.dark)
}
