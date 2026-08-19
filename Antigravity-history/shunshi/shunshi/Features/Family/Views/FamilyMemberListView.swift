import SwiftUI

struct FamilyMemberListView: View {
    @StateObject private var familySystem = FamilyCareSystem.shared
    @State private var showingAddSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            if familySystem.members.isEmpty {
                emptyStateView
            } else {
                ForEach(familySystem.members) { member in
                    FamilyMemberRow(member: member)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let member = familySystem.members[index]
                        familySystem.removeMember(member.id)
                    }
                }
            }
        }
        .navigationTitle("家庭成员")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFamilyMemberView()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无家庭成员")
                .font(.headline)
            Text("添加家人后，顺时小管家将为全家提供定制化养生建议")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyCareSystem.FamilyMember
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: member.relationship.icon)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.shunshiPrimary)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.nickname)
                    .font(.headline)
                HStack {
                    Text(member.relationship.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    if let constitution = member.constitution {
                        Text(constitution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddFamilyMemberView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var relationship: FamilyCareSystem.FamilyRelationship = .other
    @State private var constitution: String = ""
    @State private var concernsString: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("昵称", text: $name)
                    Picker("关系", selection: $relationship) {
                        ForEach(FamilyCareSystem.FamilyRelationship.allCases, id: \.self) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                }
                
                Section(header: Text("健康画像 (选填)")) {
                    TextField("体质 (如：气虚质)", text: $constitution)
                    TextField("关注点 (用逗号分隔)", text: $concernsString)
                }
            }
            .navigationTitle("添加家人")
            .navigationBarItems(
                leading: Button("取消") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("保存") {
                    saveMember()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveMember() {
        let concerns = concernsString.split(separator: "，").flatMap { $0.split(separator: ",") }.map { String($0).trimmingCharacters(in: .whitespaces) }
        
        _ = FamilyCareSystem.shared.addFamilyMember(
            nickname: name,
            relationship: relationship,
            constitution: constitution.isEmpty ? nil : constitution,
            concerns: concerns
        )
        presentationMode.wrappedValue.dismiss()
    }
}
