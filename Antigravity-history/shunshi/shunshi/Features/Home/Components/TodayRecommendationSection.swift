import SwiftUI

// MARK: - Today Recommendation Section
struct TodayRecommendationSection: View {
    let recipes: [Recipe]
    var themeColor: Color = .shunshiPrimary
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("今日推荐")
                        .font(AppTypography.sectionTitle())
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Text("查看更多")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(AppTypography.label())
                        .foregroundColor(themeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(themeColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                if !recipes.isEmpty {
                    Text("根据您的体质为您精心挑选")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
            }
            
            // Recipe Cards
            ForEach(recipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeCard(recipe: recipe)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Recipe Card
struct RecipeCard: View {
    let recipe: Recipe
    @Environment(\.colorScheme) private var colorScheme

    /// 生成食谱的AI图片提示词
    private var imagePrompt: String {
        "Delicious \(recipe.name) Chinese dish, traditional plating on ceramic plate, warm ambient lighting, food photography, appetizing, high quality"
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // AI Generated Image
            ZStack {
                if let coverImageUrl = recipe.coverImage {
                    AsyncImage(url: coverImageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.1)
                            .frame(width: 100, height: 100)
                    }
                } else {
                    AIImageView(
                        prompt: imagePrompt,
                        cacheKey: "recipe_\(recipe.id)_v2",
                        aspectRatio: 1,
                        cornerRadius: AppRadius.md
                    )
                    .frame(width: 100, height: 100)
                }

                // Category Badge
                VStack {
                    HStack {
                        Text(recipe.category.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: 100, height: 100)
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(recipe.name)
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text(recipe.description)
                    .font(AppTypography.caption())
                    .foregroundColor(Color.AppText.secondary(colorScheme))
                    .lineLimit(2)
                
                Spacer()
                
                // Meta Info
                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(recipe.cookingTime) 分钟")
                            .font(AppTypography.label())
                    }
                    .foregroundColor(Color.AppText.muted(colorScheme))
                    
                    // Constitution suitability tags
                    if let constitution = recipe.suitableFor.first {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(constitution.themeColor)
                                .frame(width: 6, height: 6)
                            Text("适合\(constitution.displayName)")
                                .font(AppTypography.label())
                                .foregroundColor(constitution.themeColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(constitution.themeColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.gray.opacity(0.1),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    TodayRecommendationSection(recipes: [.preview])
        .padding()
        .background(Color.Background.dark)
        .preferredColorScheme(.dark)
}

