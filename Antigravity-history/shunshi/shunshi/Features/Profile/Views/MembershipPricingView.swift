import SwiftUI

// MARK: - Membership Pricing View
struct MembershipPricingView: View {
    @StateObject private var viewModel = MembershipViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Header
                VStack(spacing: AppSpacing.md) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("LIMITED ACCESS")
                            .font(.system(size: 11, weight: .black))
                            .tracking(3)
                            .foregroundColor(.orange)
                    }
                    
                    Text("顺时而活，进阶自然")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    Text("开启 1+1 养生新周期，解锁全部古法智慧")
                        .font(AppTypography.subheadline())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                }
                .padding(.top, 60)
                .multilineTextAlignment(.center)
                
                // Plans
                VStack(spacing: AppSpacing.lg) {
                    ForEach(viewModel.plans) { plan in
                        PlanCard(plan: plan) {
                            Task {
                                await viewModel.purchase(plan: plan)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                
                // Trust Elements
                HStack(spacing: AppSpacing.xl) {
                    trustItem(icon: "shield.checkered", text: "苹果安全支付")
                    trustItem(icon: "clock.arrow.2.circlepath", text: "7天无理由退款")
                    trustItem(icon: "lock.fill", text: "隐私严格加密")
                }
                .padding(.vertical, AppSpacing.md)
                
                // Benefits Summary
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("会员专享权益")
                        .font(AppTypography.sectionTitle())
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        MembershipBenefitRow(icon: "sparkles", title: "AI 调理", subtitle: "基于体质的个性化每日指导")
                        MembershipBenefitRow(icon: "leaf.fill", title: "秘传食谱", subtitle: "数百道古法养生食谱全解锁")
                        MembershipBenefitRow(icon: "waveform.path.ecg", title: "深度分析", subtitle: "生成极精细的体质调理周报")
                        MembershipBenefitRow(icon: "figure.2.and.child.holdinghands", title: "家庭共享", subtitle: "一人订阅，全家共享养生关怀")
                    }
                }
                .padding(AppSpacing.lg)
                .lumeGlass()
                .padding(.horizontal, AppSpacing.md)
                
                // Footer
                VStack(spacing: AppSpacing.sm) {
                    Text("确认购买即表示您同意《服务协议》与《隐私政策》")
                        .font(.system(size: 10))
                        .foregroundColor(Color.AppText.muted(colorScheme))
                    
                    Text("如果您有任何疑问，请联系客服：support@shunshi.com")
                        .font(.system(size: 10))
                        .foregroundColor(Color.AppText.muted(colorScheme))
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(
            ZStack {
                Color.Background.adaptive(colorScheme).ignoresSafeArea()
                
                // Decorative Blobs
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .offset(x: 100, y: -200)
                    .blur(radius: 80)
                
                Circle()
                    .fill(Color.seasonAutumn.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: 150)
                    .blur(radius: 60)
            }
        )
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .alert("购买成功", isPresented: $viewModel.showAlert) {
            Button("好的") { dismiss() }
        } message: {
            if let message = viewModel.alertMessage {
                Text(message)
            }
        }
    }
    
    private func trustItem(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.AppText.muted(colorScheme))
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: MembershipPlan
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if plan.isPopular {
                        Text("超值推荐")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.shunshiPrimary)
                            .clipShape(Capsule())
                    }
                    
                    Text(plan.title)
                        .font(AppTypography.headline(20))
                        .foregroundColor(Color.AppText.primary(colorScheme))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(plan.features, id: \.self) { feature in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.shunshiPrimary)
                                Text(feature)
                                    .font(AppTypography.caption())
                                    .foregroundColor(Color.AppText.secondary(colorScheme))
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: -2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("¥")
                                .font(.system(size: 16, weight: .bold))
                            Text(plan.price.replacingOccurrences(of: "¥", with: ""))
                                .font(.system(size: 36, weight: .black))
                        }
                        .foregroundColor(.shunshiPrimary)
                        
                        Text("/ \(plan.duration == "月" ? "每月" : "每年")")
                            .font(AppTypography.caption(10))
                            .foregroundColor(Color.AppText.muted(colorScheme))
                            .fontWeight(.bold)
                    }
                    
                    Text("立即升级")
                        .font(AppTypography.label())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.shunshiPrimary, .shunshiPrimary.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        )
                        .softShadow(color: .shunshiPrimary.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.Surface.adaptive(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(plan.isPopular ? Color.shunshiPrimary : Color.clear, lineWidth: 2)
                    )
                    .softShadow(color: plan.isPopular ? .shunshiPrimary.opacity(0.1) : .black.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Benefit Row
struct MembershipBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(.shunshiPrimary)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                Text(subtitle)
                    .font(AppTypography.caption())
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .tint(.white)
                Text("正在处理...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    NavigationStack {
        MembershipPricingView()
    }
    .preferredColorScheme(.dark)
}
