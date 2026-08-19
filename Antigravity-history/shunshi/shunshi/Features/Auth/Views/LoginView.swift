import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case phone
        case code
    }
    
    var body: some View {
        ZStack {
            // Premium background
            ZStack {
                Color.Background.adaptive(.light).ignoresSafeArea()
                
                // Animated Blobs
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .offset(x: -150, y: -200)
                    .blur(radius: 80)
                
                Circle()
                    .fill(Color.seasonSpring.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: 180, y: 300)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: 40) {
                        // Logo & Title
                        headerSection
                        
                        VStack(spacing: 24) {
                            // Phone Input
                            phoneInputSection
                            
                            // Verification Code
                            if viewModel.codeSent {
                                codeInputSection
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // Login Button
                            loginButton
                                .padding(.top, 8)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                        
                        // Third Party Login
                        VStack(spacing: 24) {
                            dividerSection
                            thirdPartySection
                        }
                        .padding(.top, 20)
                        
                        // Terms
                        termsSection
                            .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.shunshiPrimary)
                                .padding(8)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .transparentNavigationStack()
            
            if showSuccess {
                AuthSuccessView {
                    dismiss()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                .zIndex(1)
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(error: $viewModel.error, onRetry: nil)
        .preferredColorScheme(.light)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [.shunshiPrimary, .shunshiPrimary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 8)
            
            Text("欢迎来到顺时")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.shunshiPrimary)
            
            Text("顺应节气，找回身体的内在节奏")
                .font(AppTypography.subheadline())
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Phone Input
    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("手机号")
                .font(AppTypography.label())
                .foregroundColor(.shunshiPrimary)
            
            HStack(spacing: 12) {
                Text("+86")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                
                TextField("请输入手机号", text: $viewModel.phoneNumber)
                    .font(.system(size: 16))
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phone)
                
                if !viewModel.phoneNumber.isEmpty {
                    Button {
                        viewModel.phoneNumber = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(focusedField == .phone ? Color.shunshiPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Code Input
    private var codeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("验证码")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField("请输入验证码", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .code)
                
                Button {
                    Task { await viewModel.sendVerificationCode() }
                } label: {
                    Text(viewModel.sendCodeButtonTitle)
                        .font(.subheadline)
                        .foregroundColor(viewModel.canSendCode ? Color.accentColor : Color.secondary)
                }
                .disabled(!viewModel.canSendCode)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Login Button
    private var loginButton: some View {
        Button {
            withAnimation(.spring()) {
                if viewModel.codeSent {
                    Task {
                        if await viewModel.login() {
                            withAnimation(.spring()) {
                                showSuccess = true
                            }
                        }
                    }
                } else {
                    Task { await viewModel.sendVerificationCode() }
                }
            }
        } label: {
            Text(viewModel.codeSent ? "立即进入" : "获取短信验证码")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        if buttonEnabled {
                            LinearGradient(colors: [.shunshiPrimary, .shunshiPrimary.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: buttonEnabled ? .shunshiPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(!buttonEnabled)
    }
    
    private var buttonEnabled: Bool {
        viewModel.codeSent ? viewModel.canLogin : viewModel.canSendCode
    }
    
    // MARK: - Divider
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            
            Text("其他登录方式")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Third Party
    private var thirdPartySection: some View {
        HStack(spacing: 40) {
            // Apple
            Button {
                Task {
                    if await viewModel.loginWithApple() {
                        dismiss()
                    }
                }
            } label: {
                Image(systemName: "apple.logo")
                    .font(.title)
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
            // WeChat
            Button {
                Task {
                    if await viewModel.loginWithWeChat() {
                        dismiss()
                    }
                }
            } label: {
                Image(systemName: "message.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Terms
    private var termsSection: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.agreedToTerms.toggle()
            } label: {
                Image(systemName: viewModel.agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.agreedToTerms ? Color.accentColor : Color.secondary)
            }
            
            Text("我已阅读并同意")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("用户协议") {
                // TODO: Show terms
            }
            .font(.caption)
            
            Text("和")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("隐私政策") {
                // TODO: Show privacy
            }
            .font(.caption)
        }
    }
}

#Preview {
    LoginView()
}

