import SwiftUI

// MARK: - Acupoint View (穴位养生)
struct AcupointView: View {
    @StateObject private var viewModel = AcupointViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: AppSpacing.lg) {
                    ForEach(viewModel.acupoints) { acupoint in
                        NavigationLink(destination: AcupointDetailView(acupoint: acupoint)) {
                            AcupointCard(acupoint: acupoint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(Color.Background.adaptive(colorScheme).ignoresSafeArea())
        }
    }
}

// MARK: - Acupoint Card
struct AcupointCard: View {
    let acupoint: Acupoint
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AIImageView(prompt: acupoint.imagePrompt, cacheKey: "acupoint_\(acupoint.id)", aspectRatio: 4/3)
                .frame(height: 200)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(acupoint.name)
                            .font(AppTypography.headline(20))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                        Text(acupoint.pinyin)
                            .font(AppTypography.caption(12))
                            .foregroundColor(Color.AppText.muted(colorScheme))
                    }
                    Spacer()
                    Text(acupoint.meridian.displayName)
                        .font(AppTypography.caption(12))
                        .foregroundColor(.shunshiPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.shunshiPrimary.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    InfoRow(icon: "mappin.circle", title: "位置", content: acupoint.location)
                    InfoRow(icon: "hand.point.up", title: "按摩方法", content: acupoint.method)
                    InfoRow(icon: "clock", title: "建议时长", content: "\(acupoint.duration)秒")
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("功效")
                            .font(AppTypography.headline(14))
                            .foregroundColor(Color.AppText.primary(colorScheme))
                        ForEach(acupoint.effects, id: \.self) { effect in
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                Text(effect)
                                    .font(AppTypography.body(14))
                                    .foregroundColor(Color.AppText.secondary(colorScheme))
                            }
                        }

                        if !acupoint.contraindications.isEmpty {
                            Text("注意事项")
                                .font(AppTypography.headline(14))
                                .foregroundColor(Color.AppText.primary(colorScheme))
                                .padding(.top, AppSpacing.sm)
                            ForEach(acupoint.contraindications, id: \.self) { item in
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                    Text(item)
                                        .font(AppTypography.body(14))
                                        .foregroundColor(Color.AppText.secondary(colorScheme))
                                }
                            }
                        }
                    }
                }
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Text(isExpanded ? "收起" : "查看详情")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(AppTypography.body(14))
                    .foregroundColor(.shunshiPrimary)
                }
            }
            .padding(AppSpacing.md)
        }
        .cardStyle()
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.shunshiPrimary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption(12))
                    .foregroundColor(Color.AppText.muted(colorScheme))
                Text(content)
                    .font(AppTypography.body(14))
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
        }
    }
}

// MARK: - Acupoint View Model
@MainActor
class AcupointViewModel: ObservableObject {
    @Published var acupoints: [Acupoint] = Acupoint.sampleData
}

// MARK: - Sample Data
extension Acupoint {
    static let sampleData: [Acupoint] = [
        Acupoint(
            id: "1", name: "足三里", pinyin: "Zú Sān Lǐ", meridian: .stomach,
            location: "小腿外侧，犊鼻下3寸，胫骨前嵴外一横指处",
            method: "用拇指指腹按压，力度适中，每次按压3-5秒后放松",
            duration: 180,
            effects: ["调理脾胃", "补中益气", "通经活络", "扶正祛邪"],
            indications: ["胃痛", "腹胀", "消化不良"],
            contraindications: ["孕妇慎用", "皮肤破损处禁用"],
            imageUrl: nil, videoUrl: nil
        ),
        Acupoint(
            id: "2", name: "合谷", pinyin: "Hé Gǔ", meridian: .largeIntestine,
            location: "手背第一、二掌骨间，第二掌骨桡侧中点处",
            method: "用另一手拇指按压，可配合揉动",
            duration: 120,
            effects: ["镇静止痛", "通经活络", "清热解表"],
            indications: ["头痛", "牙痛", "感冒"],
            contraindications: ["孕妇禁用"],
            imageUrl: nil, videoUrl: nil
        ),
        Acupoint(
            id: "3", name: "太冲", pinyin: "Tài Chōng", meridian: .liver,
            location: "足背第一、二跖骨结合部之前凹陷处",
            method: "用拇指指腹按压，由轻到重",
            duration: 120,
            effects: ["平肝息风", "清热利湿", "通络止痛"],
            indications: ["头晕", "目眩", "高血压"],
            contraindications: ["出血倾向者慎用"],
            imageUrl: nil, videoUrl: nil
        )
    ]
}

#Preview {
    AcupointView()
        .preferredColorScheme(.dark)
}

