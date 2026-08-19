import SwiftUI

struct NewcomerGuideSection: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var tasks = [
        NewcomerTask(id: 1, title: "完成体质测评", icon: "person.text.rectangle", description: "了解你的身体个性", isCompleted: false),
        NewcomerTask(id: 2, title: "与 AI 顾问对话", icon: "sparkles.bubble.fill", description: "开启第一次健康咨询", isCompleted: false),
        NewcomerTask(id: 3, title: "开启第一次记录", icon: "pencil.and.outline", description: "记录当下的身体感受", isCompleted: false)
    ]
    
    var onTaskTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("新手三件事")
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                Text("\(tasks.filter { $0.isCompleted }.count)/\(tasks.count)")
                    .font(AppTypography.caption(12))
                    .foregroundColor(.shunshiPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    Button(action: { onTaskTap(task.id) }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(task.isCompleted ? Color.green.opacity(0.1) : Color.shunshiPrimary.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: task.isCompleted ? "checkmark" : task.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(task.isCompleted ? .green : .shunshiPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(AppTypography.subheadline(14))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.AppText.primary(colorScheme))
                                
                                Text(task.description)
                                    .font(AppTypography.caption(11))
                                    .foregroundColor(Color.AppText.secondary(colorScheme))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color.AppText.muted(colorScheme))
                        }
                        .padding(AppSpacing.md)
                        .background(Color.Surface.adaptive(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("NewcomerTask_\(task.id)")
                }
            }
        }
        .onAppear {
            updateTaskStatus()
        }
    }
    
    private func updateTaskStatus() {
        // 实际上应该从服务中获取状态
        let hasCompletedConstitution = UserDefaults.standard.bool(forKey: "user_has_constitution")
        let hasTalkedToAI = UserDefaults.standard.integer(forKey: "ai_chat_count") > 0
        let hasRecord = UserDefaults.standard.integer(forKey: "wellness_record_count") > 0
        
        tasks[0].isCompleted = hasCompletedConstitution
        tasks[1].isCompleted = hasTalkedToAI
        tasks[2].isCompleted = hasRecord
    }
}

struct NewcomerTask: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let description: String
    var isCompleted: Bool
}
