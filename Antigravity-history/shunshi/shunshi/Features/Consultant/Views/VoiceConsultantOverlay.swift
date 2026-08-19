import SwiftUI

// MARK: - Voice Consultant Overlay
struct VoiceConsultantOverlay: View {
    @ObservedObject var voiceService = VoiceInteractionService.shared
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var audioLevel: Float = 0.0
    @State private var transcription: String = ""
    @State private var state: VoiceInteractionService.VoiceState = .idle
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // AI Character Bubble
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.shunshiPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.shunshiPrimary)
                        .scaleEffect(1.0 + CGFloat(audioLevel) * 0.5)
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                    
                    if isPremium {
                        Image(systemName: "shield.checkmark.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .background(Circle().fill(.white).padding(2))
                            .offset(x: 36, y: 36)
                    }
                }
                
                Text(stateTitle)
                    .font(AppTypography.headline())
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
            
            // Transcription
            ScrollView {
                Text(transcription.isEmpty ? "正在倾听..." : transcription)
                    .font(AppTypography.body())
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(height: 120)
            
            // Waveform Simulation
            HStack(spacing: 4) {
                ForEach(0..<20) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.shunshiPrimary)
                        .frame(width: 4, height: CGFloat.random(in: 4...40) * CGFloat(audioLevel + 0.1))
                }
            }
            .frame(height: 50)
            
            Spacer()
            
            // Cancel / Finish Button
            Button(action: {
                VoiceInteractionService.shared.stopVoiceConversation()
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.bottom, 50)
        }
        .padding()
        .background(Color.Background.adaptive(colorScheme).ignoresSafeArea())
        .onAppear {
            startListening()
        }
    }
    
    // Services
    private let authService = AuthService.shared
    private let storeKitService = StoreKitService.shared
    private let appStateService = AppStateService.shared
    
    // Computed Properties
    private var isPremium: Bool {
        storeKitService.subscriptionStatus.isActive
    }
    
    private var stateTitle: String {
        switch state {
        case .idle: return "顺时小师"
        case .listening: return "正在倾听..."
        case .processing: return "正在思考..."
        case .speaking: return "正在回复"
        case .error: return "出错了"
        }
    }
    
    private func startListening() {
        Task {
            do {
                // 构建完整的上下文 (Phase A/B Support)
                let userStart = AIAgentService.UserContext(
                    userId: authService.currentUser?.id ?? "guest",
                    constitution: authService.currentUser?.constitution?.primary?.type.rawValue,
                    currentSolarTerm: appStateService.currentSolarTerm?.name,
                    conversationHistory: [], // 语音对话暂不回溯长历史，由DeepContext处理
                    userProfile: authService.currentUser?.profileSummary,
                    currentMood: nil,
                    lastActiveTime: Date(),
                    isPremium: isPremium
                )
                
                // Phase D: Family Context Injection
                var context = userStart
                let systemMembers = FamilyCareSystem.shared.members
                let aiMembers = systemMembers.map { member in
                    AIAgentService.FamilyMember(
                        name: member.nickname,
                        relation: member.relationship.displayName,
                        constitution: member.constitution,
                        healthConcerns: member.healthGoals
                    )
                }
                context.familyMembers = aiMembers
                
                if !aiMembers.isEmpty && context.isPremium {
                    context.relationshipTier = .family
                }
                
                try await voiceService.startVoiceConversation(
                    context: context,
                    callback: .init(
                        onStateChanged: { self.state = $0 },
                        onAudioLevelChanged: { self.audioLevel = $0 },
                        onTranscription: { self.transcription = $0 },
                        onSpeechStarted: { },
                        onSpeechEnded: { 
                            // 语音结束后不自动关闭，等待用户手动关闭或继续对话
                        },
                        onError: { _ in state = .error }
                    )
                )
            } catch {
                state = .error
            }
        }
    }
}

// MARK: - Extension for VoiceInteractionService to be Observable
// We need to add ObservableObject support to VoiceInteractionService if it doesn't have it
// Alternatively, just use the callback as implemented.
