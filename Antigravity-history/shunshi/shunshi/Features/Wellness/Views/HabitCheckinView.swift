import SwiftUI
import Combine

// MARK: - UI习惯模型
struct UIHabit: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let category: UIHabitCategory
    let targetTimesPerDay: Int
    let currentStreak: Int
    let isCompletedToday: Bool
    let createdAt: Date
    
    enum UIHabitCategory: String, CaseIterable {
        case exercise = "运动"
        case diet = "饮食"
        case sleep = "睡眠"
        case emotion = "情志"
        case acupoint = "穴位"
        case other = "其他"
    }
}

// MARK: - 习惯打卡视图
struct HabitCheckinView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var selectedHabit: UIHabit?
    @State private var showAddHabit = false
    var careStatus: AIAgentService.CareStatus?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日打卡概览
                    todayOverview
                    
                    // 习惯列表
                    habitList
                    
                    // 打卡历史统计
                    checkinStatsSection
                    
                    // 打卡日历
                    checkinCalendarSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("习惯打卡")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddHabit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $selectedHabit) { habit in
                CheckinSuccessAnimation(
                    message: "\(habit.name) 完成！",
                    streak: habit.currentStreak
                )
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - 今日概览
    private var todayOverview: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日打卡")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.todayCompletedCount)/\(viewModel.totalHabits)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.shunshiPrimary)
                }
                
                Spacer()
                
                // 进度圆环
                ZStack {
                    Circle()
                        .stroke(Color.shunshiPrimary.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.todayProgress)
                        .stroke(
                            Color.shunshiPrimary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(viewModel.todayProgress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            // 连续打卡天数
            if viewModel.totalStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    
                    Text("连续打卡 \(viewModel.totalStreak) 天")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("再接再厉！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 习惯列表
    private var habitList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的习惯")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.habits.count)个习惯")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            if visibleHabits.isEmpty {
                emptyHabitsView
            } else {
                ForEach(visibleHabits) { habit in
                    HabitCard(habit: habit, onCheckin: {
                        viewModel.checkin(habit: habit)
                        selectedHabit = habit
                    })
                }
            }
        }
    }
    
    // Filter habits based on care status
    private var visibleHabits: [UIHabit] {
        guard let status = careStatus, status == .escalate else {
            return viewModel.habits
        }
        return viewModel.habits.filter { $0.category != .exercise }
    }
    
    private var emptyHabitsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 50))
                .foregroundColor(.shunshiPrimary.opacity(0.5))
            
            Text("还没有习惯")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击右上角添加养生习惯")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - 打卡统计
    private var checkinStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周统计")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "总打卡",
                    value: "\(viewModel.weeklyCheckinCount)",
                    subtitle: "次",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: "+5%"
                )
                
                StatCard(
                    title: "完成率",
                    value: "\(viewModel.weeklyCompletionRate)",
                    subtitle: "%",
                    icon: "chart.bar.fill",
                    color: .blue,
                    trend: "+10%"
                )
                
                StatCard(
                    title: "最长连续",
                    value: "\(viewModel.longestStreak)",
                    subtitle: "天",
                    icon: "flame.fill",
                    color: .orange,
                    trend: "最高"
                )
            }
        }
    }
    
    // MARK: - 打卡日历
    private var checkinCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("打卡日历")
                .font(.headline)
                .padding(.horizontal, 4)
            
            CheckinCalendarView(checkins: viewModel.checkinHistory)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
        }
    }
}

// MARK: - 习惯卡片
struct HabitCard: View {
    let habit: UIHabit
    let onCheckin: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 习惯图标
            ZStack {
                Circle()
                    .fill(habit.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 22))
                    .foregroundColor(habit.color)
            }
            
            // 习惯信息
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                Text(habit.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 连续打卡
                if habit.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text("\(habit.currentStreak)天")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // 打卡按钮
            Button(action: onCheckin) {
                VStack(spacing: 4) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 32))
                        .foregroundColor(habit.isCompletedToday ? .green : Color(.systemGray3))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(habit.isCompletedToday)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - 打卡日历视图
struct CheckinCalendarView: View {
    let checkins: [Date: Int]
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份导航
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            // 星期标题
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CheckinCalendarDayView(
                            date: date,
                            checkinCount: checkins[date] ?? 0,
                            isToday: calendar.isDateInToday(date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
        .padding()
    }
    
    private var daysInMonth: [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)
        guard let interval = interval else { return [] }
        let firstDay = interval.start
        
        guard let firstWeekday = calendar.dateComponents([.weekday], from: firstDay).weekday else {
            return []
        }
        
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var result: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...days {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                result.append(date)
            }
        }
        
        return result
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

// MARK: - 日历日视图
struct CheckinCalendarDayView: View {
    let date: Date
    let checkinCount: Int
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
            
            // 点
            if checkinCount > 0 {
                HStack(spacing: 2) {
                    Circle()
                        .fill(checkinColor)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.shunshiPrimary.opacity(0.15) : Color.clear)
        )
    }
    
    private var textColor: Color {
        if calendar.isDateInToday(date) {
            return .shunshiPrimary
        }
        return .primary
    }
    
    private var checkinColor: Color {
        switch checkinCount {
        case 0:
            return .clear
        case 1:
            return .green.opacity(0.6)
        case 2:
            return .green
        default:
            return .shunshiPrimary
        }
    }
}

// MARK: - 添加习惯视图
struct AddHabitView: View {
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var habitName = ""
    @State private var habitDescription = ""
    @State private var selectedIcon = "leaf.fill"
    @State private var selectedColor = Color.green
    @State private var selectedCategory: UIHabit.UIHabitCategory = .other
    
    private let icons = [
        "leaf.fill", "drop.fill", "flame.fill", "moon.fill", "sun.max.fill",
        "figure.mind.and.body", "heart.fill", "brain.head.profile",
        "hand.point.up.fill", "bed.double.fill", "fork.knife", "drop.triangle.fill"
    ]
    
    private let colors: [Color] = [.green, .blue, .orange, .purple, .red, .pink, .cyan, .yellow]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("习惯名称") {
                    TextField("例如：早起喝水", text: $habitName)
                }
                
                Section("习惯描述") {
                    TextField("例如：起床后喝一杯温水", text: $habitDescription)
                }
                
                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("选择分类") {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(UIHabit.UIHabitCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("添加习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.addHabit(
                            name: habitName,
                            description: habitDescription,
                            icon: selectedIcon,
                            color: selectedColor,
                            category: selectedCategory
                        )
                        dismiss()
                    }
                    .disabled(habitName.isEmpty)
                }
            }
        }
    }
}

// MARK: - 习惯视图模型
// MARK: - 习惯视图模型 (Adapter for HabitService)
class HabitViewModel: ObservableObject {
    @Published var habits: [UIHabit] = []
    @Published var checkinHistory: [Date: Int] = [:] // This would need a separate service or logic
    
    private var cancellables = Set<AnyCancellable>()
    private let habitService = HabitService.shared
    
    var totalHabits: Int { habits.count }
    
    var todayCompletedCount: Int {
        habits.filter { $0.isCompletedToday }.count
    }
    
    var todayProgress: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(totalHabits)
    }
    
    var totalStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }
    
    var weeklyCheckinCount: Int {
        // Mock implementation for history stats as HabitService doesn't expose history yet
        return habits.reduce(0) { $0 + $1.currentStreak }
    }
    
    var weeklyCompletionRate: Int {
        guard totalHabits > 0 else { return 0 }
        return Int(todayProgress * 100)
    }
    
    var longestStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }
    
    init() {
        // Subscribe to HabitService
        habitService.$habits
            .map { domainHabits in
                domainHabits.map { self.mapToUIHabit($0) }
            }
            .assign(to: \.habits, on: self)
            .store(in: &cancellables)
            
        // Load history mock
        loadHistoryMock()
    }
    
    private func mapToUIHabit(_ habit: Habit) -> UIHabit {
        UIHabit(
            id: habit.id.uuidString,
            name: habit.title,
            description: "坚持打卡", // Habit Entity lacks description
            icon: habit.icon,
            color: habit.category.color,
            category: mapCategory(habit.category),
            targetTimesPerDay: 1,
            currentStreak: habit.streak,
            isCompletedToday: habit.isCompletedToday,
            createdAt: Date() // Entity lacks creation date
        )
    }
    
    private func mapCategory(_ category: Habit.HabitCategory) -> UIHabit.UIHabitCategory {
        switch category {
        case .diet: return .diet
        case .exercise: return .exercise
        case .sleep: return .sleep
        case .mind: return .emotion
        case .habit: return .other
        }
    }
    
    private func mapUICategory(_ category: UIHabit.UIHabitCategory) -> Habit.HabitCategory {
        switch category {
        case .diet: return .diet
        case .exercise: return .exercise
        case .sleep: return .sleep
        case .emotion: return .mind
        case .acupoint: return .exercise // Mapping acupoint to exercise/mind
        case .other: return .habit
        }
    }
    
    func checkin(habit: UIHabit) {
        guard let uuid = UUID(uuidString: habit.id) else { return }
        if let domainHabit = habitService.habits.first(where: { $0.id == uuid }) {
            habitService.toggleHabit(domainHabit)
        }
    }
    
    func addHabit(name: String, description: String, icon: String, color: Color, category: UIHabit.UIHabitCategory) {
        habitService.addHabit(title: name, icon: icon, category: mapUICategory(category))
    }
    
    private func loadHistoryMock() {
        let today = Date()
        for i in 0..<60 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                checkinHistory[date] = Int.random(in: 0...3)
            }
        }
    }
}

// MARK: - 预览
#Preview("Habit Checkin") {
    HabitCheckinView()
}

#Preview("Habit Card") {
    HabitCard(
        habit: UIHabit(
            id: "1",
            name: "早起喝水",
            description: "起床后喝一杯温水",
            icon: "drop.fill",
            color: .blue,
            category: .diet,
            targetTimesPerDay: 1,
            currentStreak: 7,
            isCompletedToday: false,
            createdAt: Date()
        ),
        onCheckin: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
