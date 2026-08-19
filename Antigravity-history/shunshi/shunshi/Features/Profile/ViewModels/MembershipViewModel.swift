import Foundation
import SwiftUI

// MARK: - Membership View Model
final class MembershipViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false
    
    // In a real app, this would be fetched from the backend or App Store Connect
    let plans: [MembershipPlan] = [
        MembershipPlan(id: "monthly", title: "月度会员", price: "¥28", duration: "月", features: ["解锁所有高级食谱", "AI 身体调理建议", "精美节气壁纸下载", "无广告体验"]),
        MembershipPlan(id: "annual", title: "年度会员", price: "¥198", duration: "年", isPopular: true, features: ["包含月度会员所有权益", "专属节气大礼包", "家庭成员共享 (最多3人)", "优先体验新功能"])
    ]
    
    func purchase(plan: MembershipPlan) async {
        isLoading = true
        
        // Mock purchase delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // In a real app, process payment here
        
        await MainActor.run {
            isLoading = false
            alertMessage = "感谢订阅！您现在是 \(plan.title)。"
            showAlert = true
            
            // Update global membership status (Mock)
            // Typically this would update the User entity in a Repository or Service
        }
    }
}

// MARK: - Membership Plan model
struct MembershipPlan: Identifiable {
    let id: String
    let title: String
    let price: String
    let duration: String
    var isPopular: Bool = false
    let features: [String]
}
