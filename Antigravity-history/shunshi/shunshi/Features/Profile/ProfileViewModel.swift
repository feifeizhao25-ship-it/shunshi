import Foundation
import Combine

// MARK: - Profile View Model
@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var showLogoutConfirmation: Bool = false
    @Published var showDeleteAccountConfirmation: Bool = false
    
    // MARK: - Dependencies
    private let authService: AuthService
    private let appStateService: AppStateService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthService? = nil,
        appStateService: AppStateService? = nil
    ) {
        self.authService = authService ?? .shared
        self.appStateService = appStateService ?? .shared
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$user)
    }
    
    // MARK: - Computed Properties
    var isLoggedIn: Bool {
        authService.isLoggedIn
    }

    var displayName: String {
        user?.displayName ?? "未登录"
    }

    var avatarUrl: URL? {
        user?.avatarUrl
    }
    
    var constitutionText: String {
        user?.constitution?.primary?.type.displayName ?? "未测试"
    }
    
    var membershipText: String {
        guard let membership = user?.membership else { return "普通用户" }
        return membership.type.displayName
    }
    
    // MARK: - Actions
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        isLoading = true

        // Note: deleteAccount is not implemented yet - log out instead
        await authService.logout()

        isLoading = false
    }

    func refreshProfile() async {
        isLoading = true

        do {
            try await authService.refreshUser()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }

        isLoading = false
    }
}

// MARK: - Profile Section
enum ProfileSection: String, CaseIterable, Identifiable {
    case account = "account"
    case health = "health"
    case settings = "settings"
    case about = "about"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .account: return "账户"
        case .health: return "健康"
        case .settings: return "设置"
        case .about: return "关于"
        }
    }
    
    var items: [ProfileItem] {
        switch self {
        case .account:
            return [.favorites, .history, .membership]
        case .health:
            return [.constitution, .healthRecord, .reminders]
        case .settings:
            return [.notifications, .appearance, .privacy]
        case .about:
            return [.help, .feedback, .about]
        }
    }
}

// MARK: - Profile Item
enum ProfileItem: String, Identifiable {
    case favorites = "favorites"
    case history = "history"
    case membership = "membership"
    case constitution = "constitution"
    case healthRecord = "health_record"
    case reminders = "reminders"
    case notifications = "notifications"
    case appearance = "appearance"
    case privacy = "privacy"
    case help = "help"
    case feedback = "feedback"
    case about = "about"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .favorites: return "我的收藏"
        case .history: return "浏览历史"
        case .membership: return "会员中心"
        case .constitution: return "体质测试"
        case .healthRecord: return "健康档案"
        case .reminders: return "养生提醒"
        case .notifications: return "通知设置"
        case .appearance: return "外观设置"
        case .privacy: return "隐私设置"
        case .help: return "帮助中心"
        case .feedback: return "意见反馈"
        case .about: return "关于我们"
        }
    }
    
    var icon: String {
        switch self {
        case .favorites: return "heart.fill"
        case .history: return "clock.fill"
        case .membership: return "crown.fill"
        case .constitution: return "person.badge.shield.checkmark.fill"
        case .healthRecord: return "doc.text.fill"
        case .reminders: return "bell.fill"
        case .notifications: return "bell.badge.fill"
        case .appearance: return "paintbrush.fill"
        case .privacy: return "lock.fill"
        case .help: return "questionmark.circle.fill"
        case .feedback: return "envelope.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .favorites: return .red
        case .history: return .blue
        case .membership: return .yellow
        case .constitution: return .green
        case .healthRecord: return .purple
        case .reminders: return .orange
        case .notifications: return .pink
        case .appearance: return .indigo
        case .privacy: return .gray
        case .help: return .teal
        case .feedback: return .mint
        case .about: return .cyan
        }
    }
}

import SwiftUI

