import Foundation
import AVFoundation

// MARK: - Voice Interaction Service
/// 语音交互服务 - 集成讯飞ASR/TTS和AI对话
@MainActor
final class VoiceInteractionService: ObservableObject {
    static let shared = VoiceInteractionService()
    
    // 语音服务状态
    enum VoiceState {
        case idle                    // 空闲
        case listening              // 监听中
        case processing             // 处理中
        case speaking               // 说话中
        case error                  // 错误
    }
    
    // 语音配置
    private struct VoiceConfig {
        static let sampleRate: Int = 16000
        static let bitDepth: Int = 16
        static let channels: Int = 1
        static let recordingTimeout: TimeInterval = 30.0
        static let silenceTimeout: TimeInterval = 3.0
    }
    
    // 语音回调
    struct VoiceCallback {
        let onStateChanged: (VoiceState) -> Void
        let onAudioLevelChanged: (Float) -> Void
        let onTranscription: (String) -> Void
        let onSpeechStarted: () -> Void
        let onSpeechEnded: () -> Void
        let onError: (Error) -> Void
    }
    
    // 私有属性
    private var currentState: VoiceState = .idle
    private var audioEngine: AVAudioEngine?
    private var recorder: AVAudioPlayerNode?
    private var inputBus: AVAudioNodeBus
    private var recordingFormat: AVAudioFormat?
    private var isRecording = false
    private var silenceTimer: Timer?
    private var recordingTimer: Timer?
    private var currentCallback: VoiceCallback?
    
    // AI对话服务
    private let aiAgentService = AIAgentService.shared
    private let userDefaults = UserDefaults.standard
    
    // 语音设置
    private var voiceSettings: VoiceSettings {
        get {
            if let data = userDefaults.data(forKey: "VoiceSettings"),
               let settings = try? JSONDecoder().decode(VoiceSettings.self, from: data) {
                return settings
            }
            return VoiceSettings.default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: "VoiceSettings")
            }
        }
    }
    
    private init() {
        inputBus = AVAudioNodeBus(0)
        setupAudioSession()
    }
    
    // MARK: - 公共接口

    /// 开始语音对话
    func startVoiceConversation(
        message: String? = nil,
        context: AIAgentService.UserContext,
        callback: VoiceCallback
    ) async throws {
        currentCallback = callback
        updateState(.listening)

        // 如果有预设消息，直接处理
        if let message = message {
            await processVoiceMessage(message, context: context)
            return
        }

        // 开始录音
        try await startRecording()
    }

    /// 停止语音对话
    func stopVoiceConversation() {
        updateState(.idle)
        stopRecording()
        stopSpeaking()
        currentCallback = nil
    }

    /// 播放语音回复
    func speakText(_ text: String, voiceId: String? = nil) async throws {
        updateState(.speaking)

        // 使用讯飞TTS生成语音
        let audioData = try await generateSpeech(text: text, voiceId: voiceId)

        // 播放语音
        try await playAudio(audioData)

        updateState(.idle)
        currentCallback?.onSpeechEnded()
    }
    
    /// 设置语音参数
    func setVoiceParameters(speed: Float, pitch: Float, volume: Float) {
        voiceSettings.speed = speed
        voiceSettings.pitch = pitch
        voiceSettings.volume = volume
    }
    
    /// 获取支持的语音列表
    func getAvailableVoices() async -> [VoiceOption] {
        // 返回预设的语音选项
        return [
            VoiceOption(id: "xiaoming", name: "小明", gender: "男", language: "zh-CN", description: "清晰男声"),
            VoiceOption(id: "xiaoyi", name: "小艺", gender: "女", language: "zh-CN", description: "温柔女声"),
            VoiceOption(id: "xiaoli", name: "小丽", gender: "女", language: "zh-CN", description: "活泼女声"),
            VoiceOption(id: "xiaowei", name: "小伟", gender: "男", language: "zh-CN", description: "沉稳男声"),
            VoiceOption(id: "xiaoyuan", name: "小媛", gender: "女", language: "zh-TW", description: "台湾女声"),
            VoiceOption(id: "xiaogang", name: "小刚", gender: "男", language: "zh-CN", description: "东北男声")
        ]
    }
    
    // MARK: - 私有方法
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            Logger.error("设置音频会话失败: \(error)")
        }
    }
    
    /// 开始录音
    private func startRecording() async throws {
        audioEngine = AVAudioEngine()
        recorder = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let recorder = recorder else {
            throw VoiceError.engineInitializationFailed
        }
        
        // 设置录音格式
        recordingFormat = AVAudioFormat(
            standardFormatWithSampleRate: Double(VoiceConfig.sampleRate),
            channels: AVAudioChannelCount(VoiceConfig.channels)
        )
        
        // 连接音频节点
        audioEngine.attach(recorder)
        audioEngine.connect(recorder, to: audioEngine.mainMixerNode, format: recordingFormat)
        
        // 监听音频级别
        audioEngine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }
        
        // 启动音频引擎
        try audioEngine.start()
        isRecording = true
        
        // 启动超时计时器
        startTimeoutTimers()

        currentCallback?.onSpeechStarted()
    }
    
    /// 停止录音
    private func stopRecording() {
        isRecording = false
        silenceTimer?.invalidate()
        recordingTimer?.invalidate()
        
        audioEngine?.mainMixerNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        recorder = nil
    }
    
    /// 处理音频缓冲区
    private func processAudioBuffer(_ buffer: AVAudioBuffer) {
        guard let buffer = buffer as? AVAudioPCMBuffer else { return }
        
        // 计算音量级别
        let channelData = buffer.floatChannelData?[0]
        let frameLength = buffer.frameLength
        var rms: Float = 0.0
        
        for i in 0..<frameLength {
            let sample = channelData?[Int(i)] ?? 0.0
            rms += sample * sample
        }
        rms = sqrt(rms / Float(frameLength))
        
        // 归一化到0-1范围
        let normalizedLevel = min(rms * 10.0, 1.0)

        currentCallback?.onAudioLevelChanged(normalizedLevel)

        // 检测静音
        if normalizedLevel < 0.01 {
            handleSilenceDetected()
        } else {
            resetSilenceTimer()
        }
    }
    
    /// 处理静音检测
    private func handleSilenceDetected() {
        if isRecording {
            silenceTimer?.fire()
        }
    }
    
    /// 重置静音计时器
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: VoiceConfig.silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleSilenceTimeout()
            }
        }
    }
    
    /// 缓存的上下文（用于错误恢复和持续对话）
    private var lastActiveContext: AIAgentService.UserContext?

    /// 处理静音超时
    private func handleSilenceTimeout() {
        Task {
            // 使用缓存的上下文或空上下文
            let context = lastActiveContext ?? AIAgentService.UserContext(
                userId: "",
                constitution: nil,
                currentSolarTerm: nil,
                selectedWellnessTab: nil,
                conversationHistory: [],
                userProfile: nil,
                currentMood: nil,
                lastActiveTime: nil
            )
            await processVoiceMessage("静音检测超时", context: context)
        }
    }

    /// 处理超时计时器
    private func startTimeoutTimers() {
        // 录音总超时
        recordingTimer = Timer.scheduledTimer(withTimeInterval: VoiceConfig.recordingTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleRecordingTimeout()
            }
        }
    }

    /// 处理录音超时
    private func handleRecordingTimeout() {
        Task {
            let context = lastActiveContext ?? AIAgentService.UserContext(
                userId: "",
                constitution: nil,
                currentSolarTerm: nil,
                selectedWellnessTab: nil,
                conversationHistory: [],
                userProfile: nil,
                currentMood: nil,
                lastActiveTime: nil
            )
            await processVoiceMessage("录音超时", context: context)
        }
    }
    
    /// 处理语音消息
    private func processVoiceMessage(_ message: String, context: AIAgentService.UserContext) async {
        var mutableContext = context
        lastActiveContext = context // 更新活动上下文缓存
        updateState(.processing)

        do {
            // 1. 使用讯飞ASR识别语音
            let transcribedText = try await transcribeAudio(audioData: message.data(using: .utf8)!)

            currentCallback?.onTranscription(transcribedText)

            // 2. 调用AI Agent处理消息
            let aiResponse = try await aiAgentService.processUserMessage(
                message: transcribedText,
                context: &mutableContext,
                sessionId: UUID().uuidString
            )
            
            // Phase B: 处理跟进 (Voice Mode)
            if let followUp = aiResponse.followUp {
                Task {
                    await PushNotificationService.shared.scheduleFollowUp(intent: followUp)
                }
            }

            // 3. 生成语音回复
            try await speakText(aiResponse.content)

        } catch {
            currentCallback?.onError(error)
            updateState(.error)
        }
    }
    
    /// 语音转文字（讯飞ASR）
    private func transcribeAudio(audioData: Data) async throws -> String {
        // 这里实现讯飞ASR API调用
        // TODO: 实现具体的讯飞ASR API集成
        
        // 模拟识别结果
        return "您刚才说的是：\(String(data: audioData, encoding: .utf8) ?? "")"
    }
    
    /// 生成语音（讯飞TTS）
    private func generateSpeech(text: String, voiceId: String?) async throws -> Data {
        // 这里实现讯飞TTS API调用
        // TODO: 实现具体的讯飞TTS API集成
        
        // 模拟生成的音频数据
        return "模拟音频数据".data(using: .utf8)!
    }
    
    /// 播放音频
    private func playAudio(_ audioData: Data) async throws {
        // 这里实现音频播放逻辑
        // TODO: 实现具体的音频播放功能
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟播放时间
    }
    
    /// 停止播放
    private func stopSpeaking() {
        // 停止音频播放
        // TODO: 实现停止播放逻辑
    }
    
    /// 更新状态
    private func updateState(_ newState: VoiceState) {
        currentState = newState
        currentCallback?.onStateChanged(newState)
    }
    
    // MARK: - 错误处理
    private enum VoiceError: LocalizedError {
        case engineInitializationFailed
        case audioSessionFailed
        case recordingFailed
        case transcriptionFailed
        case synthesisFailed
        case playbackFailed
        
        var errorDescription: String? {
            switch self {
            case .engineInitializationFailed:
                return "音频引擎初始化失败"
            case .audioSessionFailed:
                return "音频会话设置失败"
            case .recordingFailed:
                return "录音失败"
            case .transcriptionFailed:
                return "语音识别失败"
            case .synthesisFailed:
                return "语音合成失败"
            case .playbackFailed:
                return "音频播放失败"
            }
        }
    }
}

// MARK: - 辅助类型定义
extension VoiceInteractionService {
    struct VoiceSettings: Codable {
        var speed: Float = 1.0        // 语速
        var pitch: Float = 1.0        // 音调
        var volume: Float = 1.0       // 音量
        var voiceId: String = "xiaoming" // 语音ID
        var language: String = "zh-CN"   // 语言
        
        static let `default` = VoiceSettings()
    }
    
    struct VoiceOption: Identifiable {
        let id: String
        let name: String
        let gender: String
        let language: String
        let description: String
    }
}
