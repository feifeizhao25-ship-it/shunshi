//
//  shunshiApp.swift
//  shunshi
//
//  Created by feifei00 on 2025/12/30.
//

import SwiftUI
import SwiftData

@main
struct shunshiApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var appStateService = AppStateService.shared
    @StateObject private var coordinator = AppCoordinator.shared
    @StateObject private var networkMonitor = NetworkMonitorService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            Group {
                if !coordinator.isReady {
                    LaunchScreen()
                } else if !appStateService.hasCompletedOnboarding {
                    OnboardingView(isCompleted: Binding(
                        get: { appStateService.hasCompletedOnboarding },
                        set: { if $0 { appStateService.completeOnboarding() } }
                    ))
                } else {
                    MainTabView()
                        .environmentObject(appState)
                        .environmentObject(appStateService)
                        .environmentObject(networkMonitor)
                }
            }
            .modelContainer(for: ChatMessageEntity.self, ChatSessionEntity.self)
            .preferredColorScheme(.dark)
            .task {
                await coordinator.launch()
            }
            .alert("系统维护中", isPresented: $coordinator.showMaintenanceAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(RemoteConfigService.shared.config.maintenanceMessage ?? "系统正在维护中，请稍后再试")
            }
            .alert("需要更新", isPresented: $coordinator.showForceUpdateAlert) {
                Button("前往更新") {
                    if let url = URL(string: "https://apps.apple.com/app/id000000000") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("您的应用版本过低，请更新到最新版本")
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Logger.info("App did finish launching")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Task { @MainActor in
            AppCoordinator.shared.handleAppWillResignActive()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Task { @MainActor in
            AppCoordinator.shared.handleAppDidEnterBackground()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Task { @MainActor in
            AppCoordinator.shared.handleAppWillEnterForeground()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            AppCoordinator.shared.handleAppDidBecomeActive()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Task { @MainActor in
            AppCoordinator.shared.handleAppWillTerminate()
        }
    }

    // MARK: - Push Notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.info("Device token: \(token)")
        Task { @MainActor in
            await NotificationService.shared.handleDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.error("Failed to register for remote notifications", error: error)
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var currentSolarTerm: SolarTerm = .preview
    @Published var userConstitution: ConstitutionType?
    @Published var isLoggedIn: Bool = false
}

// MARK: - Launch Screen
struct LaunchScreen: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)

                Text("顺时养生")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
