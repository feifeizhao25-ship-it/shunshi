import SwiftUI

// MARK: - Diet View (食养页面)
struct DietView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appStateService: AppStateService
    
    private var solarTerm: SolarTerm {
        appStateService.currentSolarTerm ?? .preview
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppSpacing.lg) {
                // Diet Principles Card
                dietPrinciplesCard
                
                // Seasonal Ingredients
                seasonalIngredientsSection
                
                // Recipes Section
                recipesSection
                
                // Tea Recommendations
                teaRecommendationsSection
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.lg)
        }
    }
    
    // MARK: - Diet Principles Card
    private var dietPrinciplesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Solar Term")
                        .font(AppTypography.label())
                        .foregroundColor(.shunshiPrimary.opacity(0.8))
                        .textCase(.uppercase)
                    
                    HStack(alignment: .bottom) {
                        Text(solarTerm.name)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                        
                        Text(solarTerm.nameEn)
                            .font(AppTypography.caption())
                            .foregroundColor(Color.AppText.muted(colorScheme))
                            .padding(.bottom, 6)
                    }
                }
                
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: solarTerm.icon)
                        .foregroundColor(.shunshiPrimary)
                }
            }
            
            // Description
            Text(solarTerm.healthPrinciple)
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineSpacing(4)
            
            // Yi Ji Row
            HStack(spacing: AppSpacing.md) {
                // Yi (Recommended)
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.shunshiPrimary)
                            .font(.system(size: 14))
                        Text("宜")
                            .font(AppTypography.headline(14))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                    }
                    
                    Text(solarTerm.yi.prefix(2).joined(separator: "、"))
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Surface.darkLighter.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                
                // Ji (Avoid)
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.8))
                            .font(.system(size: 14))
                        Text("忌")
                            .font(AppTypography.headline(14))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                    }
                    
                    Text(solarTerm.ji.prefix(2).joined(separator: "、"))
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Surface.darkLighter.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
        .padding(AppSpacing.lg)
        .glassmorphism()
    }
    
    // MARK: - Seasonal Ingredients Section
    private var seasonalIngredientsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("当季食材")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text("Seasonal")
                    .font(AppTypography.label())
                    .foregroundColor(.shunshiPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            // Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<4) { index in
                        IngredientCard(
                            name: ["白萝卜", "羊肉", "山药", "核桃"][index],
                            effect: ["润肺", "补虚", "健脾", "补肾"][index]
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Recipes Section
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("节气食谱")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 2) {
                        Text("全部")
                            .font(AppTypography.label())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.AppText.muted(colorScheme))
                }
            }
            
            // Recipe Cards
            ForEach(0..<2) { index in
                NavigationLink(destination: RecipeDetailView(recipe: .preview)) {
                    RecipeCard(recipe: .preview)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Tea Recommendations
    private var teaRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("养生茶饮")
                .font(AppTypography.sectionTitle())
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            HStack(spacing: AppSpacing.md) {
                TeaCard(name: "姜枣茶", effect: "温中散寒", icon: "cup.and.saucer.fill", color: .orange)
                TeaCard(name: "枸杞茶", effect: "补肝明目", icon: "leaf.fill", color: .green)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DietView()
        .background(Color.Background.dark)
        .preferredColorScheme(.dark)
}

