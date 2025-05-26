import Foundation

public struct SportsGame: Identifiable, Codable {
    public let id: String
    public let home: SportsTeam
    public let away: SportsTeam
    public let scheduled: Date
    public let status: GameStatus
    public let league: SportsLeague
    public var analysis: [BettingAnalysis]?
    
    public init(id: String, home: SportsTeam, away: SportsTeam, scheduled: Date, status: GameStatus, league: SportsLeague, analysis: [BettingAnalysis]? = nil) {
        self.id = id
        self.home = home
        self.away = away
        self.scheduled = scheduled
        self.status = status
        self.league = league
        self.analysis = analysis
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, home, away, scheduled, status, league, analysis
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        home = try container.decode(SportsTeam.self, forKey: .home)
        away = try container.decode(SportsTeam.self, forKey: .away)
        scheduled = try container.decode(Date.self, forKey: .scheduled)
        status = try container.decode(GameStatus.self, forKey: .status)
        league = try container.decode(SportsLeague.self, forKey: .league)
        analysis = try container.decodeIfPresent([BettingAnalysis].self, forKey: .analysis)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(home, forKey: .home)
        try container.encode(away, forKey: .away)
        try container.encode(scheduled, forKey: .scheduled)
        try container.encode(status, forKey: .status)
        try container.encode(league, forKey: .league)
        try container.encodeIfPresent(analysis, forKey: .analysis)
    }
}

public struct SportsTeam: Identifiable, Codable {
    public let id: String
    public let name: String
    public let abbreviation: String
    
    public init(id: String, name: String, abbreviation: String) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
    }
}

public enum GameStatus: String, Codable {
    case scheduled
    case inProgress = "in_progress"
    case final
    case postponed
    case cancelled
}

public enum SportsLeague: String, Codable {
    case nba
    case nhl
    case mlb
} 