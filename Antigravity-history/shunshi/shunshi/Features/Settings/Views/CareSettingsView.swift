import SwiftUI

struct CareSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // Feature Toggles (Persisted)
    @AppStorage("care_enableMorning") private var enableMorningCare = true
    @AppStorage("care_enableNoon") private var enableNoonCare = true
    @AppStorage("care_enableEvening") private var enableEveningCare = true
    @AppStorage("care_enableWeather") private var enableWeatherCare = true
    @AppStorage("care_enableEmotion") private var enableEmotionCare = true
    @AppStorage("care_realityMode") private var realityConnectionMode = true
    @AppStorage("care_dialogueStyle") private var dialogueStyle = "warm"
    
    // TimeSettings (Mock persistence using State for now, could be UserDefaults directly)
    @State private var morningTime = Date()
    @State private var noonTime = Date()
    @State private var eveningTime = Date()
    
    @State private var showingClearConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("智能关怀开关")) {
                Toggle(isOn: $enableMorningCare) {
                    Label("早安问候", systemImage: "sun.max.fill")
                }
                if enableMorningCare {
                    DatePicker("提醒时间", selection: $morningTime, displayedComponents: .hourAndMinute)
                }
                
                Toggle(isOn: $enableNoonCare) {
                    Label("午间调理", systemImage: "sun.horizon.fill")
                }
                if enableNoonCare {
                    DatePicker("提醒时间", selection: $noonTime, displayedComponents: .hourAndMinute)
                }
                
                Toggle(isOn: $enableEveningCare) {
                    Label("晚安叮嘱", systemImage: "moon.stars.fill")
                }
                if enableEveningCare {
                    DatePicker("提醒时间", selection: $eveningTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("动态感知")) {
                Toggle(isOn: $enableWeatherCare) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("天气感应")
                        Text("降温、干燥时自动提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $enableEmotionCare) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("情绪共鸣")
                        Text("检测到负面情绪时主动安慰")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("关怀风格")) {
                Picker("对话风格", selection: $dialogueStyle) {
                    Text("温暖治愈").tag("warm")
                    Text("日常随性").tag("casual")
                    Text("专业细致").tag("professional")
                }
            }
            
            // Phase D: 现实连接与记忆隐私
            Section(header: Text("数字健康与隐私")) {
                Toggle(isOn: $realityConnectionMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("现实连接模式")
                        Text("鼓励回归真实生活，减少AI过度依赖")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive, action: {
                    showingClearConfirmation = true
                }) {
                    Label("清除AI记忆缓存", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("主动关怀设置")
        .alert("确认清除记忆？", isPresented: $showingClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearAIMemory()
            }
        } message: {
            Text("这将删除所有历史关怀记录和对话上下文，且无法恢复。")
        }
    }
    
    private func clearAIMemory() {
        Task {
            // Clear Care History
            let userId = AuthService.shared.currentUser?.id ?? "unknown"
            await CareHistoryService.shared.clearHistory(userId: userId)
            
            // Clear UserDefaults for Voice/Family if needed (optional)
            // For now, we mainly clear the Care History which drives the AI's long term memory
        }
    }
}

#Preview {
    NavigationStack {
        CareSettingsView()
    }
}
