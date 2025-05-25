// BackgroundRefreshManager.swift
import Foundation
import SwiftUI

@MainActor
class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()
    
    // Configuration
    private let minRefreshInterval: TimeInterval = 60  // 1 minute minimum between refreshes
    private let activeRefreshInterval: TimeInterval = 300  // 5 minutes when app is active
    private let maxRefreshAttempts = 3  // Maximum retry attempts
    
    // State
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshTime: Date?
    private var refreshTask: Task<Void, Never>?
    private var retryCount = 0
    
    // Dependencies
    private let viewModel: GameBrowserViewModel
    
    private init() {
        self.viewModel = GameBrowserViewModel()
    }
    
    // MARK: - Public Interface
    
    func startBackgroundRefresh() {
        stopBackgroundRefresh()  // Cancel any existing refresh task
        
        refreshTask = Task {
            while !Task.isCancelled {
                await refreshIfNeeded()
                try? await Task.sleep(nanoseconds: UInt64(minRefreshInterval * 1_000_000_000))
            }
        }
    }
    
    func stopBackgroundRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func appBecameActive() {
        startBackgroundRefresh()
    }
    
    func appEnteredBackground() {
        stopBackgroundRefresh()
    }
    
    // MARK: - Private Methods
    
    private func refreshIfNeeded() async {
        // Don't refresh if already in progress
        guard !isRefreshing else { return }
        
        // Check if enough time has passed since last refresh
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < activeRefreshInterval {
            return
        }
        
        isRefreshing = true
        defer { 
            isRefreshing = false
            lastRefreshTime = Date()
        }
        
        do {
            // First refresh sports list
            try await viewModel.fetchSports()
            
            // Then refresh events for each expanded sport
            for sport in viewModel.sports {
                if Task.isCancelled { return }
                
                // Only refresh events that are being displayed
                if await OddsCache.shared.getCachedEvents(forSport: sport.key) != nil {
                    try await viewModel.fetchEvents(for: sport)
                }
                
                // Add small delay between sport refreshes to respect rate limits
                try await Task.sleep(nanoseconds: UInt64(1.5 * 1_000_000_000))
            }
            
            // Reset retry count on success
            retryCount = 0
            
        } catch {
            print("⚠️ Background refresh failed:", error)
            retryCount += 1
            
            // If we've failed too many times, stop background refresh
            if retryCount >= maxRefreshAttempts {
                print("❌ Too many refresh failures, stopping background updates")
                stopBackgroundRefresh()
            }
        }
    }
}

// MARK: - Scene Phase Observer
struct BackgroundRefreshModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var refreshManager = BackgroundRefreshManager.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    refreshManager.appBecameActive()
                case .background:
                    refreshManager.appEnteredBackground()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
    }
}

extension View {
    func enableBackgroundRefresh() -> some View {
        modifier(BackgroundRefreshModifier())
    }
} 