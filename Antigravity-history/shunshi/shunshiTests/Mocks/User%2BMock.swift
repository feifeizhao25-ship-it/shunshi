import Foundation
@testable import shunshi

extension User {
    static func mock(
        id: String = "123",
        phone: String = "13800138000",
        nickname: String = "测试用户"
    ) -> User {
        User(
            id: id,
            phone: phone,
            nickname: nickname,
            avatarUrl: nil,
            gender: .male,
            birthDate: nil,
            birthTime: nil,
            location: nil,
            constitution: nil,
            preferences: .default,
            stats: .empty,
            membership: .free,
            likedContents: [],
            concerns: [],
            sleepHabit: nil,
            foodPreference: nil,
            exerciseHabit: nil,
            createdAt: Date()
        )
    }
}
