import SwiftUI

// MARK: - AI Constitution Test View
struct AIConstitutionTestView: View {
    @StateObject private var viewModel = AIConstitutionTestViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var inputText: String = ""
    let solarTermName: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: viewModel.progress)
                    .tint(.shunshiPrimary)
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                            }
                            
                            if viewModel.isProcessing {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) {
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Interaction Area
                interactionArea
            }
            .background(Color.Background.adaptive(colorScheme))
            .navigationTitle("体质面对面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("稍后再说") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showResult) {
                if let result = viewModel.assessmentResult {
                    ConstitutionResultView(result: result, solarTermName: solarTermName)
                }
            }
            .task {
                await viewModel.startTest()
            }
        }
    }
    
    // MARK: - Interaction Area
    private var interactionArea: some View {
        VStack(spacing: AppSpacing.md) {
            // Quick Options for Current Question
            if let question = viewModel.currentQuestion {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(question.options, id: \.value) { option in
                            Button(action: {
                                Task { await viewModel.processUserResponse(text: option.text, value: option.value) }
                            }) {
                                Text(option.text)
                                    .font(AppTypography.subheadline())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.shunshiPrimary.opacity(0.1))
                                    .foregroundColor(.shunshiPrimary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.shunshiPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .accessibilityIdentifier("Option_\(option.value)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Text Input
            HStack(spacing: 12) {
                TextField("回复小顺...", text: $inputText)
                    .padding(12)
                    .background(Color.Surface.adaptive(colorScheme))
                    .cornerRadius(AppRadius.lg)
                    .onSubmit {
                        submitMessage()
                    }
                
                Button(action: submitMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty || viewModel.isProcessing ? .gray : .shunshiPrimary)
                }
                .disabled(inputText.isEmpty || viewModel.isProcessing)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding(.top, AppSpacing.md)
        .background(Color.Background.adaptive(colorScheme).shadow(color: .black.opacity(0.05), radius: 10, y: -5))
    }
    
    private func submitMessage() {
        let text = inputText
        inputText = ""
        Task {
            await viewModel.processUserResponse(text: text)
        }
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: AIConstitutionTestViewModel.TestChatMessage
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .font(AppTypography.body())
                .background(bubbleBackground)
                .foregroundColor(message.role == "user" ? .white : Color.AppText.primary(colorScheme))
                .cornerRadius(18)
                .overlay(alignment: message.role == "user" ? .bottomTrailing : .bottomLeading) {
                    // Slight tail (simplified)
                }
            
            if message.role == "assistant" { Spacer() }
        }
    }
    
    private var bubbleBackground: Color {
        if message.role == "user" {
            return .shunshiPrimary
        } else {
            return Color.Surface.adaptive(colorScheme)
        }
    }
}

// TypingIndicator and other components...
struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(y: i == 0 || i == 2 ? 0 : dotOffset)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(18)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                dotOffset = -5
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AIConstitutionTestView(solarTermName: "冬至")
        .preferredColorScheme(.dark)
}
