import SwiftUI

// MARK: - Wellness Category Card
struct WellnessCategoryCard: View {
    let dimension: WellnessDimension
    
    var body: some View {
        NavigationLink {
            // TODO: Navigate to dimension detail
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(dimension.displayName)
                        .font(.largeTitle.bold())
                    Text("这里将展示针对您当前体质的\(dimension.displayName)详细建议。")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        } label: {
            HStack {
                Image(systemName: dimension.icon)
                    .font(.title2)
                    .foregroundStyle(dimension.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(dimension.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("查看推荐")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Tips Section
struct TodayTipsSection: View {
    let tips: [TodayTip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "今日锦囊", icon: "lightbulb.fill")
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tips) { tip in
                        TodayTipCard(tip: tip)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Today Tip Card
struct TodayTipCard: View {
    let tip: TodayTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tip.type.icon)
                    .foregroundStyle(tip.type.color)
                Text(tip.type.shortName)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Text(tip.content)
                .font(.subheadline)
                .lineLimit(2)
            
            if let time = tip.time {
                Text(time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        HStack(spacing: 16) {
            QuickActionButton(title: "今日运势", icon: "sparkles", color: .purple)
            QuickActionButton(title: "身体自查", icon: "heart.text.square", color: .red)
            QuickActionButton(title: "智能提醒", icon: "bell.fill", color: .orange)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Wellness Dimensions Grid
struct WellnessDimensionsGrid: View {
    let dimensions: [WellnessDimension] = [.diet, .exercise, .living, .emotion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "养生维度", icon: "square.grid.2x2.fill")
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(dimensions) { dimension in
                    WellnessCategoryCard(dimension: dimension)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            TodayTipsSection(tips: [
                TodayTip(type: .diet, title: "今日饮食", content: "宜食清淡、养护脾胃", time: nil),
                TodayTip(type: .living, title: "起居调养", content: "早睡早起，避免熬夜", time: nil),
                TodayTip(type: .exercise, title: "运动建议", content: "适宜进行轻柔舒缓的运动", time: "清晨或傍晚")
            ])
            
            QuickActionsSection()
                .padding(.horizontal)
            
            WellnessDimensionsGrid()
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
