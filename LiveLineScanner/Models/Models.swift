// Models.swift
import SwiftUI
import Foundation
import UserNotifications

// MARK: - API Configuration
class APIConfig {
    static let shared = APIConfig()
    private init() {
        loadSavedKey()
    }
    
    var apiKey: String = "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "sportradar_api_key")
        }
    }
    
    private func loadSavedKey() {
        if let saved = UserDefaults.standard.string(forKey: "sportradar_api_key") {
            apiKey = saved
        }
    }
    
    var isKeyValid: Bool {
        !apiKey.isEmpty
    }
}

// MARK: - API Models
struct Market: Codable {
    let key: String
    let outcomes: [Outcome]
}

struct Outcome: Codable {
    let name: String
    let price: Double
}

struct Bookmaker: Codable {
    let key: String
    let markets: [Market]
}

struct SportEvent: Codable {
    let id: String
    let scheduled: Date
    let start_time: Date
    let status: String
    let tournament_round: TournamentRound?
    let season: Season
    let competitors: [Competitor]
    
    enum CodingKeys: String, CodingKey {
        case id, scheduled, status
        case start_time = "start_time"
        case tournament_round = "tournament_round"
        case season, competitors
    }
}

struct TournamentRound: Codable {
    let number: Int
}

struct Season: Codable {
    let name: String
    let start_date: String
    let end_date: String
    let year: String
    let tournament_id: String
}

struct Competitor: Codable {
    let id: String
    let name: String
    let country: String
    let qualifier: String  // "home" or "away"
}

struct SportType: Codable, Hashable, Identifiable {
    let key: String
    let title: String
    
    var id: String { key }  // Conform to Identifiable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    static let mappings: [String: String] = [
        "sr:sport:1": "Soccer",
        "sr:sport:2": "Basketball",
        "sr:sport:3": "Baseball",
        "sr:sport:4": "Ice Hockey",
        "sr:sport:5": "Tennis",
        "sr:sport:6": "American Football",
        "sr:sport:7": "Rugby",
        "sr:sport:8": "Golf",
        "sr:sport:9": "Boxing",
        "sr:sport:10": "MMA",
        "sr:sport:11": "Cricket",
        "sr:sport:12": "Volleyball",
        "sr:sport:13": "Handball",
        "sr:sport:14": "E-Sports"
    ]
}

// Sport model for the-odds-api.com
struct APISport: Codable, Identifiable {
    let key: String
    let group: String
    let title: String
    let description: String
    let active: Bool
    let has_outrights: Bool
    
    var id: String { key }
}

struct EventOdds: Codable {
    let bookmakers: [Bookmaker]
}

struct ScheduleResponse: Codable {
    let sport_event: SportEvent
    let markets: [Market]?
    let bookmakers: [Bookmaker]?
}

// MARK: - View Models
struct OddsLine: Identifiable {
    let id = UUID()
    let market: String
    let outcome: String
    var bestPrice: Double
    var bestBook: String
    var previousPrice: Double?
    var allQuotes: [Quote] = []

    var movement: Double? {
        guard let prev = previousPrice else { return nil }
        return bestPrice - prev
    }

    var movementColor: Color {
        guard let prev = previousPrice else { return .primary }
        return bestPrice > prev ? Color.themeUp : (bestPrice < prev ? Color.themeDown : .primary)
    }
}

struct Quote: Identifiable {
    let book: String
    let price: Double
    
    var id: String { book }
}

enum SortOption: String, CaseIterable, Identifiable {
    case moveMagnitude
    case market
    case alphabetical

    var id: String { rawValue }
    var title: String {
        switch self {
        case .moveMagnitude: return "By Movement"
        case .market: return "By Market"
        case .alphabetical: return "Outcome A–Z"
        }
    }
}

// MARK: - Sports Browser Models
struct Event: Identifiable, Codable, Equatable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let commenceTime: Date
    let sportKey: String
    let completed: Bool
    let scores: [String: Double]?
    let lastUpdate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case commenceTime = "commence_time"
        case sportKey = "sport_key"
        case completed
        case scores
        case lastUpdate = "last_update"
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sort Options
enum EventSortOption: String, CaseIterable {
    case time = "Start Time"
    case homeTeam = "Home Team"
    case awayTeam = "Away Team"
    
    func sort(_ events: [Event]) -> [Event] {
        switch self {
        case .time:
            return events.sorted { $0.commenceTime < $1.commenceTime }
        case .homeTeam:
            return events.sorted { $0.homeTeam < $1.homeTeam }
        case .awayTeam:
            return events.sorted { $0.awayTeam < $1.awayTeam }
        }
    }
}

// MARK: - Notification Manager
actor NotificationState {
    private(set) var scheduledNotifications: Set<String> = []
    
    func contains(_ id: String) -> Bool {
        scheduledNotifications.contains(id)
    }
    
    func insert(_ id: String) {
        scheduledNotifications.insert(id)
    }
    
    func remove(_ id: String) {
        scheduledNotifications.remove(id)
    }
    
    func setAll(_ notifications: Set<String>) {
        scheduledNotifications = notifications
    }
}

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let state = NotificationState()
    @Published private(set) var scheduledNotificationIds: Set<String> = []
    
    private init() {
        loadScheduledNotifications()
    }
    
    nonisolated func hasNotification(for eventId: String) async -> Bool {
        await state.contains(eventId)
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .authorized {
                return true
            }
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("❌ Notification permission error:", error)
            return false
        }
    }
    
    func scheduleNotification(for event: Event) async -> Bool {
        guard await requestNotificationPermission() else { return false }
        
        let content = UNMutableNotificationContent()
        content.title = "Game Starting Soon"
        content.body = "\(event.homeTeam) vs \(event.awayTeam) starts in 15 minutes"
        content.sound = .default
        
        // Schedule 15 minutes before game time
        let triggerDate = event.commenceTime.addingTimeInterval(-15 * 60)
        guard triggerDate > Date() else { return false }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "game_\(event.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            await state.insert(event.id)
            scheduledNotificationIds = await Set(state.scheduledNotifications)
            return true
        } catch {
            print("❌ Failed to schedule notification:", error)
            return false
        }
    }
    
    func cancelNotification(for event: Event) {
        Task {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["game_\(event.id)"])
            await state.remove(event.id)
            scheduledNotificationIds = await Set(state.scheduledNotifications)
        }
    }
    
    private func loadScheduledNotifications() {
        Task {
            let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let eventIds = Set(requests.map { $0.identifier.replacingOccurrences(of: "game_", with: "") })
            await state.setAll(eventIds)
            scheduledNotificationIds = eventIds
        }
    }
}

// MARK: - Game Browser View Model
@MainActor
class GameBrowserViewModel: ObservableObject {
    @Published var sports: [SportType] = []
    @Published var events: [String: [Event]] = [:]    // sportKey → events
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortOption: EventSortOption = .time
    
    private let service = SportradarOddsService()
    private let cache = OddsCache.shared
    let session = URLSession.shared
    
    init() {
        // Set the Sportradar API key if not already set
        if APIConfig.shared.apiKey.isEmpty {
            APIConfig.shared.apiKey = "YOUR_API_KEY_HERE" // Replace with your actual API key
        }
    }
    
    func sortedEvents(for sportKey: String) -> [Event] {
        sortOption.sort(events[sportKey] ?? [])
    }

    /// 1) Fetch available sports with odds coverage
    func fetchSports() async throws {
        // Check cache first
        if let cachedSports = await cache.getCachedSports() {
            sports = cachedSports
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch schedules for prematch odds to determine available sports
            let schedules = try await service.fetchSchedules(
                product: .prematch,
                sport: "all"  // Special value to get all sports
            )
            
            // Extract unique sport keys and map to titles
            let sportKeys = Set(schedules.compactMap { schedule -> String? in
                let components = schedule.sport_event.id.split(separator: ":")
                guard components.count >= 3 else { return nil }
                return "sr:sport:\(components[2])"
            })
            
            // Create Sport objects with mapped titles
            let newSports = sportKeys.map { key in
                SportType(
                    key: key,
                    title: SportType.mappings[key] ?? key.replacingOccurrences(of: "sr:sport:", with: "")
                )
            }.sorted(by: { $0.title < $1.title })
            
            // Update cache and published state
            await cache.cacheSports(newSports)
            sports = newSports
            errorMessage = nil
            
        } catch let error as OddsError {
            switch error {
            case .invalidAPIKey:
                errorMessage = "Invalid API key. Please check your settings."
            case .unauthorized:
                errorMessage = "Unauthorized. Please check your API key."
            case .networkError(let err):
                errorMessage = "Network error: \(err.localizedDescription)"
            case .invalidResponse:
                errorMessage = "Invalid response from server."
            case .decodingError(let err):
                errorMessage = "Failed to decode response: \(err.localizedDescription)"
            }
            print("⚠️ fetchSports:", error)
            throw error
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ fetchSports:", error)
            throw error
        }
    }

    /// 2) Fetch upcoming/live events for a sport
    func fetchEvents(for sport: SportType) async throws {
        // Check if we need to throttle API calls
        if await cache.shouldThrottle(forSport: sport.key) {
            return
        }
        
        // Check cache first
        if let cachedSchedules = await cache.getCachedEvents(forSport: sport.key) {
            updateEvents(for: sport, with: cachedSchedules)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get schedules with event details
            let schedules = try await service.fetchSchedules(
                product: .prematch,
                sport: sport.key.replacingOccurrences(of: "sr:sport:", with: "")
            )
            
            // Update cache
            await cache.cacheEvents(schedules, forSport: sport.key)
            
            // Update UI
            updateEvents(for: sport, with: schedules)
            errorMessage = nil
            
        } catch let error as OddsError {
            switch error {
            case .invalidAPIKey:
                errorMessage = "Invalid API key. Please check your settings."
            case .unauthorized:
                errorMessage = "Unauthorized. Please check your API key."
            case .networkError(let err):
                errorMessage = "Network error: \(err.localizedDescription)"
            case .invalidResponse:
                errorMessage = "Invalid response from server."
            case .decodingError(let err):
                errorMessage = "Failed to decode response: \(err.localizedDescription)"
            }
            print("⚠️ fetchEvents:", error)
            throw error
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ fetchEvents:", error)
            throw error
        }
    }
    
    private func updateEvents(for sport: SportType, with schedules: [ScheduleResponse]) {
        // Convert schedule responses to Event models
        let sportEvents = schedules.compactMap { schedule -> Event? in
            let sportEvent = schedule.sport_event
            
            // Find home and away teams
            guard let home = sportEvent.competitors.first(where: { $0.qualifier == "home" }),
                  let away = sportEvent.competitors.first(where: { $0.qualifier == "away" })
            else { return nil }
            
            return Event(
                id: sportEvent.id,
                homeTeam: home.name,
                awayTeam: away.name,
                commenceTime: sportEvent.start_time,
                sportKey: sport.key,
                completed: sportEvent.status == "closed",
                scores: nil,  // TODO: Add scores from live data if available
                lastUpdate: Date()
            )
        }
        
        events[sport.key] = sportEvents
    }
    
    /// Force refresh data, bypassing cache
    func forceRefresh() async throws {
        await cache.clearCache()
        try await fetchSports()
        for sport in sports {
            try await fetchEvents(for: sport)
        }
    }
    
    /// Force refresh a specific sport's events
    func forceRefresh(sport: SportType) async throws {
        await cache.clearCache(forSport: sport.key)
        try await fetchEvents(for: sport)
    }
} 
