import Foundation
import Combine

// MARK: - Auth View Model
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var codeSent: Bool = false
    @Published var countdown: Int = 0
    @Published var agreedToTerms: Bool = false
    
    // MARK: - Dependencies
    private let authService: AuthService
    
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService? = nil) {
        self.authService = authService ?? .shared
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
    
    // MARK: - Computed Properties
    var isPhoneValid: Bool {
        phoneNumber.count == 11 && phoneNumber.hasPrefix("1")
    }
    
    var isCodeValid: Bool {
        verificationCode.count == 6
    }
    
    var canSendCode: Bool {
        isPhoneValid && countdown == 0 && agreedToTerms
    }
    
    var canLogin: Bool {
        isPhoneValid && isCodeValid && agreedToTerms
    }
    
    var sendCodeButtonTitle: String {
        if countdown > 0 {
            return "\(countdown)秒后重发"
        }
        return codeSent ? "重新发送" : "获取验证码"
    }
    
    // MARK: - Send Verification Code
    func sendVerificationCode() async {
        guard canSendCode else { return }

        isLoading = true
        error = nil

        do {
            _ = try await authService.sendSMS(phone: phoneNumber, scene: "login")
            codeSent = true
            startCountdown()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }

        isLoading = false
    }

    // MARK: - Login
    func login() async -> Bool {
        guard canLogin else { return false }

        isLoading = true
        error = nil

        do {
            try await authService.loginWithPhone(phone: phoneNumber, code: verificationCode)
            isLoading = false
            return true
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }

        isLoading = false
        return false
    }

    // MARK: - Third Party Login
    func loginWithApple() async -> Bool {
        isLoading = true
        error = nil

        do {
            // TODO: Implement Apple Sign In flow to get authorization code
            let authorizationCode = "" // This should come from ASAuthorizationController
            try await authService.loginWithApple(code: authorizationCode)
            isLoading = false
            return true
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }

        isLoading = false
        return false
    }

    func loginWithWeChat() async -> Bool {
        isLoading = true
        error = nil

        do {
            // TODO: Implement WeChat login flow to get authorization code
            let authorizationCode = "" // This should come from WeChat SDK
            try await authService.loginWithWeChat(code: authorizationCode)
            isLoading = false
            return true
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }

        isLoading = false
        return false
    }
    
    // MARK: - Private Methods
    private func startCountdown() {
        countdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.countdownTimer?.invalidate()
                }
            }
        }
    }
    
    // MARK: - Reset
    func reset() {
        phoneNumber = ""
        verificationCode = ""
        codeSent = false
        countdown = 0
        error = nil
        countdownTimer?.invalidate()
    }
}

