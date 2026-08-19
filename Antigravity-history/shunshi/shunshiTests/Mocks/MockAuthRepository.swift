import Foundation
@testable import shunshi

class MockAuthRepository: AuthRepositoryProtocol {
    var sendSMSReturnValue: SMSResult = SMSResult(expireIn: 300, retryAfter: 60)
    var loginWithPhoneReturnValue: AuthResult?
    var loginWithOAuthReturnValue: AuthResult?
    var refreshTokenReturnValue: TokenResult?
    var logoutCalled = false
    var isLoggedInValue = false
    var accessTokenValue: String?
    
    var errorToThrow: Error?

    func sendSMS(phone: String, scene: String) async throws -> SMSResult {
        if let error = errorToThrow { throw error }
        return sendSMSReturnValue
    }

    func loginWithPhone(phone: String, code: String) async throws -> AuthResult {
        if let error = errorToThrow { throw error }
        guard let result = loginWithPhoneReturnValue else {
            throw AppError.unauthorized
        }
        return result
    }

    func loginWithOAuth(provider: String, code: String) async throws -> AuthResult {
        if let error = errorToThrow { throw error }
        guard let result = loginWithOAuthReturnValue else {
            throw AppError.unauthorized
        }
        return result
    }

    func refreshToken(_ refreshToken: String) async throws -> TokenResult {
        if let error = errorToThrow { throw error }
        guard let result = refreshTokenReturnValue else {
            throw AppError.unauthorized
        }
        return result
    }

    func logout() async throws {
        if let error = errorToThrow { throw error }
        logoutCalled = true
    }

    var isLoggedIn: Bool {
        return isLoggedInValue
    }

    var accessToken: String? {
        return accessTokenValue
    }

    func clearAuthData() {
        isLoggedInValue = false
        accessTokenValue = nil
    }
}
