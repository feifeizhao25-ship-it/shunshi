import Foundation
import Combine

// MARK: - Family Care View Model
@MainActor
final class FamilyCareViewModel: ObservableObject {
    @Published var familyMembers: [FamilyCareSystem.FamilyMember] = []
    @Published var pendingInvitations: [FamilyCareSystem.FamilyInvitation] = []
    @Published var careMessages: [FamilyCareSystem.CareMessage] = []
    @Published var isLoading: Bool = false
    @Published var alertMessage: String?
    
    private let familySystem = FamilyCareSystem.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        // In a real app, this would fetch from a database or API
        self.familyMembers = [
            FamilyCareSystem.FamilyMember(id: "1", nickname: "妈妈", relationship: .mother, avatar: nil, phoneNumber: nil, birthday: nil, constitution: "气虚质", healthGoals: [], isLinked: true, linkedUserId: "u1", membershipGifted: true, createdAt: Date(), lastActiveAt: Date()),
            FamilyCareSystem.FamilyMember(id: "2", nickname: "爸爸", relationship: .father, avatar: nil, phoneNumber: nil, birthday: nil, constitution: "阳虚质", healthGoals: [], isLinked: false, linkedUserId: nil, membershipGifted: false, createdAt: Date(), lastActiveAt: nil)
        ]
        
        // Simulate a care message (e.g., father didn't check in)
        self.careMessages = [
            FamilyCareSystem.CareMessage(id: "m1", type: .health, title: "打卡提醒", content: "爸爸今天还没有完成'午后散步'打卡，记得提醒他哦。", senderName: "物理系统", receiverId: "current_user", sentAt: Date(), isRead: false)
        ]
        
        isLoading = false
    }
    
    func sendGreeting(to member: FamilyCareSystem.FamilyMember) {
        let message = familySystem.sendCareMessage(to: member.id, type: .greeting)
        alertMessage = "已向\(member.nickname)发送问候: \(message.content)"
    }
    
    func remindMember(to member: FamilyCareSystem.FamilyMember) {
        let message = familySystem.sendCareMessage(to: member.id, type: .health)
        alertMessage = "已向\(member.nickname)发送健康提醒"
    }
    
    func giftMembership(to member: FamilyCareSystem.FamilyMember) {
        _ = familySystem.giftMembership(to: member.id, duration: 31)
        alertMessage = "正在为\(member.nickname)开通会员..."
    }
}
