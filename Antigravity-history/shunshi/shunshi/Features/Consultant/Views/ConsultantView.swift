import SwiftUI

// MARK: - Consultant View (AI养生顾问)
struct ConsultantView: View {
    @StateObject private var viewModel = ConsultantViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceOverlay = false
    @State private var showQuickAction = true
    
    var body: some View {
        ZStack {
            // Background
            Color.Background.adaptive(colorScheme)
                .ignoresSafeArea()
            
            // Decorative gradient
            VStack {
                RadialGradient(
                    colors: [Color.shunshiPrimary.opacity(0.05), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 300)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                consultantHeader
                
                // Chat Messages
                chatMessagesView
                
                // Quick Questions + Input
                bottomSection
            }
        }
        .fullScreenCover(isPresented: $showVoiceOverlay) {
            VoiceConsultantOverlay(isPresented: $showVoiceOverlay)
        }
        .padding(.bottom, AppSize.tabBarHeight)
        .task {
            await viewModel.startNewSession()
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in viewModel.error = nil }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "未知错误")
        }
    }
    
    // MARK: - Header
    private var consultantHeader: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.Surface.adaptive(colorScheme))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .foregroundColor(.shunshiPrimary)
                
                // Online indicator
                Circle()
                    .fill(Color.shunshiPrimary)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.Background.adaptive(colorScheme), lineWidth: 2)
                    )
                    .offset(x: 12, y: 12)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("顺时小师")
                    .font(AppTypography.headline(17))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                    .accessibilityIdentifier("ConsultantHeaderTitle")
                
                Text("二十四节气生活指南")
                    .font(AppTypography.label())
                    .foregroundColor(.shunshiPrimary.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .glassmorphism(cornerRadius: 0)
    }
    
    // MARK: - Chat Messages
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.lg) {
                    // Timestamp
                    Text("今日 14:02 · 处暑")
                        .font(AppTypography.label())
                        .foregroundColor(Color.AppText.muted(colorScheme).opacity(0.6))
                        .padding(.vertical, AppSpacing.md)

                    if showQuickAction {
                        quickActionCard
                    }
                    
                    // Messages
                    ForEach(viewModel.messages) { message in
                        ChatMessageBubble(message: message)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 160)
            }
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Suggested Questions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        QuickQuestionChip(text: question) {
                            Task {
                                await viewModel.sendSuggestedQuestion(question)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            
            // Input Bar
            HStack(spacing: AppSpacing.md) {
                // Mic Button
                Button(action: { showVoiceOverlay = true }) {
                    Image(systemName: "mic")
                        .font(.system(size: 20))
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                
                // Text Input
                HStack {
                    TextField("想了解什么养生习惯或节气建议？", text: $viewModel.inputText)
                        .font(AppTypography.body())
                        .focused($isInputFocused)
                        .accessibilityIdentifier("TextField")
                        .onSubmit {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
                .background(Color.Surface.adaptive(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                
                // Send Button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.Background.dark)
                        .frame(width: 44, height: 44)
                        .background(Color.shunshiPrimary)
                        .clipShape(Circle())
                        .shadow(color: .shunshiPrimary.opacity(0.4), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.vertical, AppSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.Background.adaptive(colorScheme).opacity(0), Color.Background.adaptive(colorScheme)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Quick Action Card
    private var quickActionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.shunshiPrimary)
                Text("今天我们先做个 1 分钟放松")
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                Spacer()
            }

            Text("吸气4拍，停2拍，呼气6拍。跟着我一起慢慢来。")
                .font(AppTypography.body(14))
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineSpacing(4)

            Button(action: {
                showQuickAction = false
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("我完成了")
                }
                .font(AppTypography.label(13))
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.shunshiPrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(Color.shunshiPrimary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.shunshiPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Preview
#Preview {
    ConsultantView()
        .preferredColorScheme(.dark)
}
