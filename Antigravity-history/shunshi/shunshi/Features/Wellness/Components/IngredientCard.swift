import SwiftUI

// MARK: - Ingredient Card
struct IngredientCard: View {
    let name: String
    let effect: String
    var imageURL: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    /// 生成食材的AI图片提示词
    private var imagePrompt: String {
        "Fresh \(name) ingredient, traditional Chinese food photography, elegant presentation on wooden surface, soft natural lighting, shallow depth of field, high quality, appetizing"
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Image with AI generation
            ZStack {
                if let imageURL = imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 138)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.1)
                            .frame(width: 110, height: 138)
                    }
                } else {
                    AIImageView(
                        prompt: imagePrompt,
                        cacheKey: "ingredient_\(name)_raw_v2", // Force regeneration with v2
                        aspectRatio: 4/5,
                        cornerRadius: AppRadius.lg
                    )
                    .frame(width: 110, height: 138)
                }

                // Gradient Overlay
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // Effect Tag
                VStack {
                    Spacer()
                    HStack {
                        Text(effect)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(.ultraThinMaterial)
                            .background(Color.shunshiPrimary.opacity(0.3))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(AppSpacing.sm)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            // Name
            Text(name)
                .font(AppTypography.body(14))
                .foregroundColor(Color.AppText.primary(colorScheme))
        }
    }
}

// MARK: - Tea Card
struct TeaCard: View {
    let name: String
    let effect: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Decorative Circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color.opacity(0.8))
            }
            
            Text(name)
                .font(AppTypography.headline(14))
                .foregroundColor(Color.AppText.primary(colorScheme))
            
            Text(effect)
                .font(AppTypography.label())
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .overlay(
            // Decorative blur
            Circle()
                .fill(color.opacity(0.05))
                .frame(width: 64, height: 64)
                .blur(radius: 20)
                .offset(x: 20, y: -20),
            alignment: .topTrailing
        )
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    let title: String
    let icon: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color.AppText.muted(colorScheme).opacity(0.3))
            
            Text("\(title)功能开发中...")
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Background.adaptive(colorScheme))
    }
}

// MARK: - Preview
#Preview {
    ScrollView(.horizontal) {
        HStack {
            IngredientCard(name: "白萝卜", effect: "润肺")
            IngredientCard(name: "羊肉", effect: "补虚")
        }
        .padding()
    }
    .background(Color.Background.dark)
    .preferredColorScheme(.dark)
}

