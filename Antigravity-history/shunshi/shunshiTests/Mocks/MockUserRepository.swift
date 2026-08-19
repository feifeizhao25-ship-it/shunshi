import Foundation
@testable import shunshi

class MockUserRepository: UserRepositoryProtocol {
    var getProfileReturnValue: User?
    var updateProfileReturnValue: User?
    var uploadAvatarReturnValue: URL = URL(string: "https://example.com/avatar.jpg")!
    var updatePreferencesCalled = false
    var currentUserValue: User?
    var clearCacheCalled = false
    
    var errorToThrow: Error?

    func getProfile() async throws -> User {
        if let error = errorToThrow { throw error }
        guard let user = getProfileReturnValue else {
            throw AppError.dataNotFound
        }
        return user
    }


    func updateProfile(_ update: ProfileUpdate) async throws -> User {
        if let error = errorToThrow { throw error }
        guard let user = updateProfileReturnValue else {
            throw AppError.operationFailed("Mock update failed")
        }
        return user
    }

    func uploadAvatar(data: Data) async throws -> URL {
        if let error = errorToThrow { throw error }
        return uploadAvatarReturnValue
    }

    func updatePreferences(_ preferences: UserPreferences) async throws {
        if let error = errorToThrow { throw error }
        updatePreferencesCalled = true
    }

    var currentUser: User? {
        return currentUserValue
    }

    func clearCache() {
        clearCacheCalled = true
    }
}
