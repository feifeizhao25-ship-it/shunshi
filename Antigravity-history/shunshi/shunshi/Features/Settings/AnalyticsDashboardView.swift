import SwiftUI
import Charts

// MARK: - Analytics Dashboard View
/// 数据分析看板 - 展示北极星指标、增长、活跃、变现等核心数据
struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    // 北极星指标
                    NorthStarMetricCard(metric: viewModel.northStarMetric)
                        .padding(.horizontal, Spacing.page)
                    
                    // 核心指标网格
                    MetricsGridView(metrics: viewModel.coreMetrics)
                        .padding(.horizontal, Spacing.page)
                    
                    // 增长趋势图
                    GrowthTrendChart(data: viewModel.growthTrendData)
                        .padding(.horizontal, Spacing.page)
                    
                    // 用户留存曲线
                    RetentionChart(data: viewModel.retentionData)
                        .padding(.horizontal, Spacing.page)
                    
                    // 意图分布
                    IntentDistributionChart(data: viewModel.intentDistribution)
                        .padding(.horizontal, Spacing.page)
                    
                    // 内容表现TOP5
                    TopContentSection(contents: viewModel.topContents)
                        .padding(.horizontal, Spacing.page)
                }
                .padding(.vertical, Spacing.section)
            }
            .background(AppBackground.light)
            .navigationTitle("数据看板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        viewModel.refresh()
                    }
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - North Star Metric Card
struct NorthStarMetricCard: View {
    let metric: NorthStarMetric
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Text("北极星指标")
                .font(.caption)
                .foregroundColor(AppText.tertiary)
            
            Text("\(metric.value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
            
            HStack(spacing: Spacing.small) {
                Image(systemName: metric.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(metric.change >= 0 ? .green : .red)
                
                Text("\(abs(metric.change))%")
                    .font(.caption)
                    .foregroundColor(metric.change >= 0 ? .green : .red)
                
                Text("vs 上月")
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            
            Text("月活跃付费用户数")
                .font(.caption2)
                .foregroundColor(AppText.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xlarge)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct NorthStarMetric {
    let value: Int
    let change: Double
}

// MARK: - Metrics Grid View
struct MetricsGridView: View {
    let metrics: [CoreMetric]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.small) {
            ForEach(metrics, id: \.name) { metric in
                MetricCard(metric: metric)
            }
        }
    }
}

struct MetricCard: View {
    let metric: CoreMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(SeasonalColors.currentSeasonPrimary)
                Text(metric.name)
                    .font(.caption)
                    .foregroundColor(AppText.tertiary)
            }
            
            Text(metric.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppText.primary)
            
            HStack(spacing: 4) {
                Text(metric.changeText)
                    .font(.caption2)
                    .foregroundColor(metric.changeColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct CoreMetric {
    let name: String
    let icon: String
    let value: String
    let changeText: String
    let changeColor: Color
}

// MARK: - Growth Trend Chart
struct GrowthTrendChart: View {
    let data: [TrendDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("增长趋势")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            if #available(iOS 16.0, *) {
                Chart(data) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("用户数", point.value)
                    )
                    .foregroundStyle(SeasonalColors.currentSeasonPrimary.gradient)
                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("用户数", point.value)
                    )
                    .foregroundStyle(SeasonalColors.currentSeasonPrimary.opacity(0.1).gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                // Fallback for older iOS
                SimpleLineChart(data: data)
                    .frame(height: 200)
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Simple Line Chart (Fallback)
struct SimpleLineChart: View {
    let data: [TrendDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map { $0.value }.max() ?? 1
            let minValue = data.map { $0.value }.min() ?? 0
            let range = maxValue - minValue
            
            Path { path in
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - ((CGFloat(point.value - minValue) / CGFloat(range)) * geometry.size.height * 0.8)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(SeasonalColors.currentSeasonPrimary, style: StrokeStyle(lineWidth: 2))
        }
    }
}

// MARK: - Retention Chart
struct RetentionChart: View {
    let data: [RetentionData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("留存曲线")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            HStack(spacing: Spacing.small) {
                ForEach(data, id: \.period) { item in
                    VStack(spacing: 4) {
                        Text("\(item.rate)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppText.primary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SeasonalColors.currentSeasonPrimary)
                            .frame(height: CGFloat(item.rate) / 100 * 100)
                        
                        Text(item.period)
                            .font(.caption2)
                            .foregroundColor(AppText.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct RetentionData {
    let period: String
    let rate: Int
}

// MARK: - Intent Distribution Chart
struct IntentDistributionChart: View {
    let data: [IntentData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("AI对话意图分布")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            if #available(iOS 16.0, *) {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("占比", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("意图", item.intent))
                    .cornerRadius(4)
                }
                .frame(height: 200)
            } else {
                // Fallback
                VStack(spacing: Spacing.small) {
                    ForEach(data, id: \.intent) { item in
                        HStack {
                            Text(item.intent)
                                .font(.caption)
                                .foregroundColor(AppText.primary)
                            Spacer()
                            Text("\(item.count)%")
                                .font(.caption)
                                .foregroundColor(SeasonalColors.currentSeasonPrimary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct IntentData: Identifiable {
    let id = UUID()
    let intent: String
    let count: Double
}

// MARK: - Top Content Section
struct TopContentSection: View {
    let contents: [TopContent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("热门内容 TOP5")
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            VStack(spacing: Spacing.small) {
                ForEach(Array(contents.enumerated()), id: \.element.id) { index, content in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(SeasonalColors.currentSeasonPrimary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(SeasonalColors.currentSeasonPrimary.opacity(0.1))
                            )
                        
                        Text(content.title)
                            .font(.subheadline)
                            .foregroundColor(AppText.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(content.views)")
                            .font(.caption)
                            .foregroundColor(AppText.tertiary)
                    }
                    .padding(.vertical, Spacing.small)
                }
            }
        }
        .padding(Spacing.card)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(AppBackground.card)
        )
    }
}

struct TopContent: Identifiable {
    let id = UUID()
    let title: String
    let views: Int
}

// MARK: - Analytics Dashboard ViewModel
class AnalyticsDashboardViewModel: ObservableObject {
    @Published var northStarMetric = NorthStarMetric(value: 12345, change: 15.5)
    @Published var coreMetrics: [CoreMetric] = []
    @Published var growthTrendData: [TrendDataPoint] = []
    @Published var retentionData: [RetentionData] = []
    @Published var intentDistribution: [IntentData] = []
    @Published var topContents: [TopContent] = []
    
    init() {
        loadMockData()
    }
    
    func refresh() {
        // TODO: 从后端API获取真实数据
        loadMockData()
    }
    
    private func loadMockData() {
        coreMetrics = [
            CoreMetric(name: "新增用户", icon: "person.badge.plus", value: "5,234", changeText: "+12%", changeColor: .green),
            CoreMetric(name: "留存率", icon: "person.2", value: "45.2%", changeText: "+3%", changeColor: .green),
            CoreMetric(name: "人均时长", icon: "clock", value: "8.5分钟", changeText: "+5%", changeColor: .green),
            CoreMetric(name: "转化率", icon: "dollarsign.circle", value: "5.2%", changeText: "+0.5%", changeColor: .green)
        ]
        
        // 生成趋势数据
        let calendar = Calendar.current
        let today = Date()
        growthTrendData = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return TrendDataPoint(date: date, value: Double.random(in: 1000...5000))
        }.reversed()
        
        retentionData = [
            RetentionData(period: "次日", rate: 42),
            RetentionData(period: "7日", rate: 25),
            RetentionData(period: "30日", rate: 15)
        ]
        
        intentDistribution = [
            IntentData(intent: "养生咨询", count: 45),
            IntentData(intent: "情感陪伴", count: 25),
            IntentData(intent: "日常闲聊", count: 15),
            IntentData(intent: "打卡操作", count: 10),
            IntentData(intent: "其他", count: 5)
        ]
        
        topContents = [
            TopContent(title: "小雪节气养生指南", views: 12543),
            TopContent(title: "气虚质调理方案", views: 9876),
            TopContent(title: "红枣枸杞茶做法", views: 8765),
            TopContent(title: "八段锦完整教程", views: 7654),
            TopContent(title: "足三里穴位按摩", views: 6543)
        ]
    }
}

// MARK: - Preview
#Preview("Analytics Dashboard") {
    AnalyticsDashboardView()
}
