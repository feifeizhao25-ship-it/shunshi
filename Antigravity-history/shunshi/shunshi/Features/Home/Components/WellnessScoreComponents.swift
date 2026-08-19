import SwiftUI

// MARK: - Wellness Score Card Compact (核心卡片 - 增强版)
struct WellnessScoreCardCompact: View {
    @ObservedObject var recordService: WellnessRecordService
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: CGFloat = 0.0
    
    private var todayScore: Int {
        recordService.calculateTodayScore()
    }
    
    private var healthStatus: HealthStatus {
        recordService.getHealthStatus()
    }
    
    private var wellnessLevel: WellnessLevel {
        recordService.getWellnessLevel()
    }
    
    private var metrics: [WellnessMetric] {
        recordService.getTodayMetrics()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题行：等级 + 健康状态
            HStack {
                // 等级徽章
                HStack(spacing: 6) {
                    Image(systemName: wellnessLevel.icon)
                        .font(.system(size: 14))
                    Text(wellnessLevel.name)
                        .font(AppTypography.subheadline(14).bold())
                }
                .foregroundColor(wellnessLevel.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(wellnessLevel.color.opacity(0.15))
                )
                
                Spacer()
                
                // 健康状态
                HStack(spacing: 4) {
                    Image(systemName: healthStatus.icon)
                        .font(.system(size: 12))
                    Text(healthStatus.message)
                        .font(AppTypography.caption(12))
                }
                .foregroundColor(healthStatus.color)
            }
            
            // 主体：环形进度 + 等级进度
            HStack(spacing: 20) {
                // 环形进度
                ZStack {
                    Circle()
                        .stroke(healthStatus.color.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: animatedProgress * (CGFloat(todayScore) / 100))
                        .stroke(healthStatus.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.5), value: animatedProgress)
                    
                    VStack(spacing: 2) {
                        Text("\(todayScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(healthStatus.color)
                        Text("分")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 等级进度信息
                VStack(alignment: .leading, spacing: 8) {
                    Text(wellnessLevel.description)
                        .font(AppTypography.caption(12))
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                    
                    // 等级进度条
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("距离\(wellnessLevel.nextLevelName)")
                                .font(AppTypography.caption(10))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(wellnessLevel.progress * 100))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(wellnessLevel.color)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(wellnessLevel.color)
                                    .frame(width: geometry.size.width * wellnessLevel.progress, height: 6)
                                    .shadow(color: wellnessLevel.color.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            
            // 五维指标进度条
            VStack(spacing: 8) {
                ForEach(metrics) { metric in
                    WellnessMetricRow(metric: metric)
                }
            }
            
            // 健康建议
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text(healthStatus.description)
                    .font(.system(size: 11))
                    .foregroundColor(Color.AppText.secondary(colorScheme))
            }
            .padding(.top, 4)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color.Surface.adaptive(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(Color.shunshiPrimary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation {
                animatedProgress = 1.0
            }
        }
    }
}

// MARK: - Wellness Metric Row
struct WellnessMetricRow: View {
    let metric: WellnessMetric
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            // 图标
            Image(systemName: metric.icon)
                .font(.system(size: 14))
                .foregroundColor(metric.color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(metric.color.opacity(0.15))
                )
            
            // 标题
            Text(metric.title)
                .font(AppTypography.caption(12))
                .foregroundColor(Color.AppText.primary(colorScheme))
                .frame(width: 36, alignment: .leading)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(metric.color)
                        .frame(width: geometry.size.width * metric.progress, height: 6)
                }
            }
            .frame(height: 6)
            
            // 分数
            Text("\(metric.score)/\(metric.maxScore)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(metric.color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
