import SwiftUI

// MARK: - Chat Message Bubble
struct ChatMessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if message.role == .assistant {
                // Avatar
                Circle()
                    .fill(Color.Surface.adaptive(colorScheme))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.shunshiPrimary)
                    )
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: AppSpacing.sm) {
                if message.role == .assistant {
                    Text("顺时小师")
                        .font(AppTypography.label())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }

                // Message Content
                Text(message.content)
                    .font(AppTypography.body())
                    .foregroundColor(
                        message.role == .user
                            ? Color.Background.dark
                            : Color.AppText.primary(colorScheme)
                    )
                    .padding(AppSpacing.md)
                    .background(
                        message.role == .user
                            ? Color.shunshiPrimary
                            : Color.Surface.adaptive(colorScheme).opacity(0.7)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(
                                message.role == .user
                                    ? .clear
                                    : Color.white.opacity(0.05),
                                lineWidth: 1
                            )
                    )

                // Recommendation Cards
                if !message.recommendations.isEmpty {
                    ForEach(message.recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }

                if message.role == .user {
                    Text("已读")
                        .font(AppTypography.label())
                        .foregroundColor(Color.AppText.muted(colorScheme).opacity(0.5))
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: ChatRecommendation
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            ZStack {
                Rectangle()
                    .fill(Color.Surface.darkLighter)
                    .frame(height: 120)

                Image(systemName: iconForType(recommendation.type))
                    .font(.system(size: 40))
                    .foregroundColor(Color.AppText.muted(colorScheme).opacity(0.3))

                // Badge
                VStack {
                    Spacer()
                    HStack {
                        Text(badgeTextForType(recommendation.type))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.Background.dark)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(Color.shunshiPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(recommendation.title)
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))

                Text(recommendation.description)
                    .font(AppTypography.caption())
                    .foregroundColor(Color.AppText.muted(colorScheme))
                    .lineLimit(2)

                // Action Button
                Button(action: {}) {
                    HStack {
                        Text(actionTextForType(recommendation.type))
                            .font(AppTypography.body(13))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.shunshiPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
            }
            .padding(AppSpacing.md)
        }
        .background(Color(hexCode: "132E2B"))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func iconForType(_ type: ChatRecommendation.RecommendationType) -> String {
        switch type {
        case .recipe: return "fork.knife"
        case .ingredient: return "leaf.fill"
        case .exercise: return "figure.walk"
        case .acupoint: return "hand.point.up.fill"
        case .article: return "doc.text.fill"
        }
    }

    private func badgeTextForType(_ type: ChatRecommendation.RecommendationType) -> String {
        switch type {
        case .recipe: return "食疗推荐"
        case .ingredient: return "食材推荐"
        case .exercise: return "运动推荐"
        case .acupoint: return "穴位推荐"
        case .article: return "文章推荐"
        }
    }

    private func actionTextForType(_ type: ChatRecommendation.RecommendationType) -> String {
        switch type {
        case .recipe: return "查看食谱"
        case .ingredient: return "查看详情"
        case .exercise: return "查看运动"
        case .acupoint: return "查看穴位"
        case .article: return "阅读文章"
        }
    }
}

// MARK: - Quick Question Chip
struct QuickQuestionChip: View {
    let text: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTypography.label())
                .foregroundColor(.shunshiPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.shunshiPrimary.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.shunshiPrimary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

