import Foundation
import Combine

// MARK: - Family Service
final class FamilyService: ObservableObject {
    static let shared = FamilyService()
    
    @Published var members: [AIAgentService.FamilyMember] = []
    
    private let kFamilyMembersKey = "user_family_members"
    
    private init() {
        loadMembers()
    }
    
    // MARK: - CRUD
    
    func addMember(name: String, relation: String, constitution: String?, concerns: [String]) {
        let member = AIAgentService.FamilyMember(
            name: name,
            relation: relation,
            constitution: constitution,
            healthConcerns: concerns
        )
        members.append(member)
        saveMembers()
    }
    
    func updateMember(at index: Int, member: AIAgentService.FamilyMember) {
        guard index >= 0 && index < members.count else { return }
        members[index] = member
        saveMembers()
    }
    
    func removeMember(at index: Int) {
        guard index >= 0 && index < members.count else { return }
        members.remove(at: index)
        saveMembers()
    }
    
    // MARK: - Persistence
    
    private func saveMembers() {
        if let data = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(data, forKey: kFamilyMembersKey)
        }
    }
    
    private func loadMembers() {
        guard let data = UserDefaults.standard.data(forKey: kFamilyMembersKey),
              let loaded = try? JSONDecoder().decode([AIAgentService.FamilyMember].self, from: data) else {
            return
        }
        self.members = loaded
    }
}
