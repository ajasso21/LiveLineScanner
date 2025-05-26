import Foundation

/// The supported leagues
public enum League: String, CaseIterable {
    case nba, mlb, nhl, nfl
    public var title: String { rawValue.uppercased() }
}

/// Whether to fetch today's or tomorrow's games
public enum DayOption: String, CaseIterable {
    case today, tomorrow
}

/// Simple game model used throughout the app
public struct Game: Identifiable {
    public let id: String
    public let home: String
    public let away: String
    public let startTime: Date
    
    public init(id: String, home: String, away: String, startTime: Date) {
        self.id = id
        self.home = home
        self.away = away
        self.startTime = startTime
    }
} 