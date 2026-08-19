import SwiftUI

// MARK: - Constitution Result View
struct ConstitutionResultView: View {
    let result: ConstitutionSystem.ConstitutionResult
    let solarTermName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header Card
                    headerSection
                    
                    // Characteristics
                    characteristicsSection
                    
                    // Trend Analysis (NEW)
                    trendSection
                    
                    // 3-Dimension Preview (Detailed recommendations are in the system)
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        HStack {
                            SectionHeader(title: "专属生活建议", icon: "sparkles")
                                .foregroundColor(.shunshiPrimary)
                            Spacer()
                            NavigationLink(destination: ConditioningPlanView(constitution: result.primaryConstitution.displayName, solarTerm: solarTermName)) {
                                HStack(spacing: 4) {
                                    Text("查看详情")
                                        .font(AppTypography.caption())
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.shunshiPrimary)
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                            ResultAdviceCard(title: "饮食", icon: "fork.knife", content: result.recommendations.diet.first?.items.joined(separator: "、") ?? "均衡饮食", color: .orange)
                            ResultAdviceCard(title: "运动", icon: "figure.walk", content: result.recommendations.exercise.first?.name ?? "适度有氧", color: .green)
                            ResultAdviceCard(title: "起居", icon: "moon.zzz.fill", content: result.recommendations.living.first?.title ?? "作息规律", color: .indigo)
                            ResultAdviceCard(title: "穴位", icon: "hand.point.up.fill", content: result.recommendations.acupoint.first?.name ?? "经常按揉", color: .pink)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Confidence / Note
                    HStack {
                        Image(systemName: "info.circle")
                        Text("体质受近期作息影响，建议每月进行一次复测")
                            .font(AppTypography.caption())
                    }
                    .foregroundColor(.gray)
                    .padding(.top)
                    
                    // Action
                    Button(action: { dismiss() }) {
                        Text("完成，开始养生之旅")
                            .font(AppTypography.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.shunshiPrimary)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: .shunshiPrimary.opacity(0.3), radius: 10, y: 5)
                    }
                    .accessibilityIdentifier("FinishTestButton")
                    .padding(.horizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .background(Color.Background.adaptive(colorScheme))
            .navigationTitle("你的体质画像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: WellnessReportView(solarTerm: .preview)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "历史趋势", icon: "chart.line.uptrend.xyaxis")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("你的【\(result.primaryConstitution.displayName)】频率指数已下降 12%")
                    .font(AppTypography.caption())
                    .foregroundColor(.green)
                
                // Mock Trend Line
                HStack(alignment: .bottom, spacing: 16) {
                    ForEach([0.8, 0.7, 0.9, 0.6, 0.55], id: \.self) { val in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(val > 0.7 ? Color.gray.opacity(0.1) : Color.shunshiPrimary)
                                .frame(width: 30, height: val * 80)
                            
                            Text("1.\(Int(val * 10))")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
            }
            .padding()
            .background(Color.Surface.adaptive(colorScheme))
            .cornerRadius(AppRadius.lg)
        }
        .padding(.horizontal)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hexCode: result.primaryConstitution.color).opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Text(result.primaryConstitution.displayName.prefix(2))
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(Color(hexCode: result.primaryConstitution.color))
            }
            
            Text(result.primaryConstitution.displayName)
                .font(.system(size: 32, weight: .bold))
            
            if let secondary = result.secondaryConstitution {
                Text("兼有\(secondary.displayName)")
                    .font(AppTypography.subheadline())
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.shunshiPrimary.opacity(0.05)
                LinearGradient(colors: [.clear, Color.Background.adaptive(colorScheme)], startPoint: .top, endPoint: .bottom)
            }
        )
    }
    
    private var characteristicsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "体质特征", icon: "person.text.rectangle")
            
            FlowLayout(spacing: 8) {
                ForEach(result.characteristics, id: \.self) { char in
                    Text(char)
                        .font(AppTypography.caption())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.Surface.adaptive(colorScheme))
                        .cornerRadius(AppRadius.md)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ResultAdviceCard: View {
    let title: String
    let icon: String
    let content: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AppTypography.subheadline(15))
                    .fontWeight(.medium)
            }
            
            Text(content)
                .font(AppTypography.caption())
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .cornerRadius(AppRadius.lg)
    }
}

// MARK: - Preview
#Preview {
    ConstitutionResultView(result: .init(
        primaryConstitution: .qiDeficiency,
        secondaryConstitution: .yangDeficiency,
        confidence: 0.85,
        scores: [:],
        characteristics: ["容易疲劳", "自汗", "语声微弱"],
        recommendations: .init(diet: [], exercise: [], living: [], acupoint: [], emotion: [], lifestyle: []),
        improvementTips: [],
        testDate: Date()
    ), solarTermName: "冬至")
    .preferredColorScheme(.dark)
}
