import Testing
import Foundation
@testable import shunshi

@MainActor
struct AuthViewModelTests {
    
    // MARK: - Validation Tests
    
    @Test func testPhoneValidation() {
        let viewModel = AuthViewModel(authService: createMockAuthService())
        
        viewModel.phoneNumber = "13800138000"
        #expect(viewModel.isPhoneValid == true)
        
        viewModel.phoneNumber = "23800138000" // Not starting with 1
        #expect(viewModel.isPhoneValid == false)
        
        viewModel.phoneNumber = "1380013800" // Too short
        #expect(viewModel.isPhoneValid == false)
        
        viewModel.phoneNumber = "138001380000" // Too long
        #expect(viewModel.isPhoneValid == false)
    }
    
    @Test func testCodeValidation() {
        let viewModel = AuthViewModel(authService: createMockAuthService())
        
        viewModel.verificationCode = "123456"
        #expect(viewModel.isCodeValid == true)
        
        viewModel.verificationCode = "12345"
        #expect(viewModel.isCodeValid == false)
    }
    
    @Test func testCanSendCode() {
        let viewModel = AuthViewModel(authService: createMockAuthService())
        
        viewModel.phoneNumber = "13800138000"
        viewModel.agreedToTerms = false
        #expect(viewModel.canSendCode == false)
        
        viewModel.agreedToTerms = true
        #expect(viewModel.canSendCode == true)
        
        viewModel.countdown = 30
        #expect(viewModel.canSendCode == false)
    }
    
    // MARK: - Action Tests
    
    @Test func testSendVerificationCodeSuccess() async {
        let mockRepo = MockAuthRepository()
        let authService = AuthService(authRepository: mockRepo)
        let viewModel = AuthViewModel(authService: authService)
        
        viewModel.phoneNumber = "13800138000"
        viewModel.agreedToTerms = true
        
        await viewModel.sendVerificationCode()
        
        #expect(viewModel.codeSent == true)
        #expect(viewModel.countdown == 60)
        #expect(viewModel.error == nil)
    }
    
    @Test func testLoginSuccess() async {
        let mockAuthRepo = MockAuthRepository()
        let mockUserRepo = MockUserRepository()
        
        let user = User.mock(id: "123", phone: "13800138000", nickname: "Tester")
        let authResult = AuthResult(
            accessToken: "token", 
            refreshToken: "refresh", 
            expiresIn: 3600, 
            isNewUser: false, 
            user: user
        )

        
        mockAuthRepo.loginWithPhoneReturnValue = authResult
        mockUserRepo.getProfileReturnValue = user
        
        let authService = AuthService(authRepository: mockAuthRepo, userRepository: mockUserRepo)
        let viewModel = AuthViewModel(authService: authService)
        
        viewModel.phoneNumber = "13800138000"
        viewModel.verificationCode = "123456"
        viewModel.agreedToTerms = true
        
        let success = await viewModel.login()
        
        #expect(success == true)
        #expect(viewModel.error == nil)
        #expect(authService.isLoggedIn == true)
        #expect(authService.currentUser?.id == "123")
    }
    
    @Test func testLoginFailure() async {
        let mockAuthRepo = MockAuthRepository()
        mockAuthRepo.errorToThrow = AppError.unauthorized
        
        let authService = AuthService(authRepository: mockAuthRepo)
        let viewModel = AuthViewModel(authService: authService)
        
        viewModel.phoneNumber = "13800138000"
        viewModel.verificationCode = "000000"
        viewModel.agreedToTerms = true
        
        let success = await viewModel.login()
        
        #expect(success == false)
        #expect(viewModel.error == .unauthorized)
    }

    
    // MARK: - Helpers
    
    private func createMockAuthService() -> AuthService {
        return AuthService(authRepository: MockAuthRepository(), userRepository: MockUserRepository())
    }
}
