import SwiftUI

struct ConditioningPlanView: View {
    @StateObject private var viewModel = ConditioningPlanViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let constitution: String
    let solarTerm: String
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header: Plan Info
                    planHeader
                    
                    // Core Principles (NEW)
                    if let principles = viewModel.plan?.corePrinciples {
                        principlesSection(principles)
                    }
                    
                    // Day Selector
                    daySelector
                    
                    // Tasks for Selected Day
                    dayTasksSection
                    
                    // Diet Recommendations
                    dietSection
                    
                    // Bottom Tips
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.shunshiPrimary)
                        Text("坚持是养生最重要的习惯")
                            .font(AppTypography.caption())
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                }
                .padding(.bottom, 40)
            }
            .background(Color.Background.adaptive(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI周计划 · \(solarTerm)")
                        .font(AppTypography.headline(16))
                }
            }
            .blur(radius: viewModel.isLoading ? 10 : 0)
            
            // Loading Overlay
            if viewModel.isLoading {
                aiLoadingOverlay
            }
        }
        .task {
            await viewModel.loadPlan(constitution: constitution, solarTerm: solarTerm)
        }
    }
    
    private var aiLoadingOverlay: some View {
        ZStack {
            Color.Background.adaptive(colorScheme).opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.shunshiPrimary.opacity(0.1), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.shunshiPrimary)
                        .symbolEffect(.pulse)
                }
                
                VStack(spacing: 8) {
                    Text("小顺正在为你量身定制...")
                        .font(AppTypography.headline())
                    Text("基于【\(constitution)】与【\(solarTerm)】")
                        .font(AppTypography.caption())
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func principlesSection(_ principles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "养生重心", icon: "sparkles")
            
            HStack(spacing: 12) {
                ForEach(principles, id: \.self) { principle in
                    Text(principle)
                        .font(AppTypography.caption(12))
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.shunshiPrimary.opacity(0.1))
                        .foregroundColor(.shunshiPrimary)
                        .cornerRadius(AppRadius.md)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var planHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前体质")
                        .font(AppTypography.caption())
                        .foregroundColor(.shunshiPrimary)
                    Text(constitution)
                        .font(AppTypography.headline(24))
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.shunshiPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("30%")
                        .font(AppTypography.caption(12))
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.shunshiPrimary.opacity(0.05))
            .cornerRadius(AppRadius.lg)
            .padding(.horizontal)
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(1...7, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text("D\(day)")
                            .font(AppTypography.caption())
                            .foregroundColor(viewModel.selectedDay == day ? .white : .gray)
                        Circle()
                            .fill(viewModel.selectedDay == day ? .white : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(width: 45, height: 50)
                    .background(viewModel.selectedDay == day ? Color.shunshiPrimary : Color.Surface.adaptive(colorScheme))
                    .cornerRadius(12)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { 
                            viewModel.selectedDay = day 
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var dayTasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            SectionHeader(title: "今日任务", icon: "checklist")
            
            if let tasks = viewModel.currentDayTasks {
                VStack(spacing: 16) {
                    TaskRow(time: "清晨", title: "晨间习惯", detail: tasks.morning, icon: "sun.haze.fill", color: .orange)
                    TaskRow(time: "午后", title: "日间活力", detail: tasks.afternoon, icon: "sun.max.fill", color: .green)
                    TaskRow(time: "入睡", title: "夜间安稳", detail: tasks.evening, icon: "moon.stars.fill", color: .indigo)
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .padding(.horizontal)
    }
    
    private var dietSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "饮食建议", icon: "leaf.fill")
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("宜多食")
                        .font(AppTypography.caption())
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.plan?.recommendedFoods ?? [], id: \.self) { item in
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 4, height: 4)
                                Text(item).font(.system(size: 13))
                            }
                        }
                    }
                }
                .modifier(CardModifier())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("少接触")
                        .font(AppTypography.caption())
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.plan?.avoidedFoods ?? [], id: \.self) { item in
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 4, height: 4)
                                Text(item).font(.system(size: 13))
                            }
                        }
                    }
                }
                .modifier(CardModifier())
            }
        }
        .padding(.horizontal)
    }
}

private struct TaskRow: View {
    let time: String
    let title: String
    let detail: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDone = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(time)
                    .font(AppTypography.caption(10))
                    .foregroundColor(.gray)
            }
            .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline(16))
                Text(detail)
                    .font(AppTypography.caption())
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: { isDone.toggle() }) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isDone ? .shunshiPrimary : .gray.opacity(0.3))
            }
        }
        .padding()
        .background(Color.Surface.adaptive(colorScheme))
        .cornerRadius(AppRadius.lg)
    }
}

private struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.Surface.adaptive(colorScheme))
            .cornerRadius(AppRadius.lg)
    }
}

#Preview {
    NavigationStack {
        ConditioningPlanView(constitution: "气虚质", solarTerm: "大雪")
    }
    .preferredColorScheme(.dark)
}
