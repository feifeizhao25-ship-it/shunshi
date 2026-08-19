import Foundation
import Combine

// MARK: - App State Service
@MainActor
final class AppStateService: ObservableObject {
    static let shared = AppStateService()
    
    // MARK: - Published Properties
    @Published private(set) var currentSolarTerm: SolarTerm?
    @Published private(set) var isLoadingSolarTerm: Bool = false
    @Published var selectedTab: AppTab = .home
    @Published var selectedWellnessTab: WuWeiType = .diet
    @Published var hasCompletedOnboarding: Bool
    
    // MARK: - Dependencies
    private let solarTermRepository: SolarTermRepositoryProtocol
    private let userDefaults: UserDefaults
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    init(
        solarTermRepository: SolarTermRepositoryProtocol = SolarTermRepository.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.solarTermRepository = solarTermRepository
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: AppConstants.StorageKeys.hasCompletedOnboarding)
        
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Load Initial Data
    func loadInitialData() async {
        await loadCurrentSolarTerm()
    }
    
    // MARK: - Load Current Solar Term
    func loadCurrentSolarTerm(forceRefresh: Bool = false) async {
        // Use cache if available and not forcing refresh
        if !forceRefresh, let cached = solarTermRepository.cachedCurrentSolarTerm {
            currentSolarTerm = cached
            return
        }
        
        isLoadingSolarTerm = true
        
        do {
            currentSolarTerm = try await solarTermRepository.getCurrentSolarTerm(location: nil)
            Logger.info("Loaded current solar term: \(currentSolarTerm?.name ?? "none")")
        } catch {
            Logger.error("Failed to load solar term", error: error)
            // Use cached if available
            currentSolarTerm = solarTermRepository.cachedCurrentSolarTerm
        }
        
        isLoadingSolarTerm = false
    }
    
    // MARK: - Complete Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: AppConstants.StorageKeys.hasCompletedOnboarding)
    }
    
    // MARK: - Reset Onboarding (for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: AppConstants.StorageKeys.hasCompletedOnboarding)
    }
    
    // MARK: - Private Methods
    private func setupRefreshTimer() {
        // Refresh solar term data every hour
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadCurrentSolarTerm(forceRefresh: true)
            }
        }
    }
}

// AppTab is defined in App/MainTabView.swift

