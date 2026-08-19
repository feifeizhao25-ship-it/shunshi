import SwiftUI

// MARK: - Solar Term Detail View
struct SolarTermDetailView: View {
    let solarTerm: SolarTerm
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.Background.adaptive(colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    headerSection
                    
                    // Main Content
                    VStack(spacing: AppSpacing.lg) {
                        // 5-Dimensional Wellness Advice
                        if let advice = solarTerm.wellnessAdvice {
                            wellnessAdviceSection(advice)
                        }
                        
                        // Customs Section
                        if !solarTerm.customs.isEmpty {
                            customsSection
                        }
                        
                        // Description
                        descriptionSection
                        
                        // San Hou (三候)
                        sanHouSection
                        
                        // Yi Ji (宜忌)
                        yiJiSection
                        
                        // Poem
                        if let poem = solarTerm.poem {
                            poemSection(poem)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, -AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wellnessAdviceSection(_ advice: SolarTerm.WellnessAdvice) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "专属养生指南", icon: "sparkles")
                .foregroundColor(.shunshiPrimary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                WellnessDimensionCard(title: "食养", icon: "fork.knife", items: advice.diet, color: .orange)
                WellnessDimensionCard(title: "饮茶", icon: "cup.and.saucer.fill", items: advice.drink, color: .teal)
                WellnessDimensionCard(title: "起居", icon: "moon.zzz.fill", items: advice.living, color: .indigo)
                WellnessDimensionCard(title: "动养", icon: "figure.walk", items: advice.exercise, color: .green)
                WellnessDimensionCard(title: "穴位", icon: "hand.point.up.fill", items: advice.acupoint, color: .pink)
                WellnessDimensionCard(title: "情志", icon: "heart.fill", items: advice.emotion, color: .purple)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            // Background with Gradient & Blur
            ZStack {
                solarTerm.themeColor.opacity(0.4)
                
                AIImageView(
                    prompt: "Traditional Chinese ink wash painting of \(solarTerm.name), artistic, ethereal background",
                    cacheKey: "solarterm_detail_bg_\(solarTerm.id)",
                    aspectRatio: 1,
                    cornerRadius: 0
                )
                .blur(radius: 20)
                .opacity(0.6)
            }
            .frame(height: 320)
            
            LinearGradient(
                colors: [.clear, Color.Background.adaptive(colorScheme)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            
            VStack(spacing: 8) {
                Text(solarTerm.name)
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                
                Text(solarTerm.nameEn)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    Text("\(solarTerm.startDate.monthDayString) - \(solarTerm.endDate.monthDayString)")
                    Text("•")
                    Text("第 \(solarTerm.currentDay) 天")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "节气简介", icon: "doc.text")
            
            Text(solarTerm.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    // MARK: - San Hou Section
    private var sanHouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "三候", icon: "leaf")
            
            VStack(spacing: 12) {
                ForEach(solarTerm.sanHou) { hou in
                    SanHouRow(sanHou: hou, themeColor: solarTerm.themeColor)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    // MARK: - Yi Ji Section
    private var yiJiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "宜忌", icon: "checkmark.circle")
            
            HStack(alignment: .top, spacing: 16) {
                // Yi
                VStack(alignment: .leading, spacing: 8) {
                    Label("宜", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    
                    ForEach(solarTerm.yi, id: \.self) { item in
                        Text("• " + item)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Ji
                VStack(alignment: .leading, spacing: 8) {
                    Label("忌", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    ForEach(solarTerm.ji, id: \.self) { item in
                        Text("• " + item)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    // MARK: - Poem Section
    private func poemSection(_ poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "节气诗词", icon: "book")
            
            VStack(spacing: 8) {
                Text(poem.title)
                    .font(.headline)
                
                Text(poem.fullAuthor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(poem.content)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
    }
    
    // MARK: - Keywords Section
    private var customsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "节气民俗", icon: "tent")
            
            FlowLayout(spacing: 8) {
                ForEach(solarTerm.customs, id: \.self) { custom in
                    Text(custom)
                        .font(AppTypography.caption())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.Surface.adaptive(colorScheme))
                        .cornerRadius(AppRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(Color.shunshiPrimary.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var keywordsSection: some View {
        EmptyView() // Moved keywords or merged into description
    }
}

// MARK: - Wellness Dimension Card
struct WellnessDimensionCard: View {
    let title: String
    let icon: String
    let items: [String]
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AppTypography.subheadline(15))
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                        .lineLimit(2)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - San Hou Row
struct SanHouRow: View {
    let sanHou: SanHou
    let themeColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("第\(sanHou.index)候")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sanHou.isCurrent ? themeColor : .gray)
                .clipShape(Capsule())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sanHou.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(sanHou.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(sanHou.isCurrent ? themeColor.opacity(0.05) : Color(.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sanHou.isCurrent ? themeColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }
}

// FlowLayout is defined in Core/UI/Components/FlowLayout.swift

