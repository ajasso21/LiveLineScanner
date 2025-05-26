import Foundation

public struct BettingAnalysis: Codable {
    private let gameId: String
    public let betType: BetType
    public let selection: String
    public let odds: Double
    public let winProbability: Double
    public let expectedValue: Double
    public let kellyStake: Double
    
    public var game: SportsGame? {
        // This will be set after decoding
        return nil
    }
    
    public init(game: SportsGame, betType: BetType, selection: String, odds: Double, winProbability: Double, expectedValue: Double, kellyStake: Double) {
        self.gameId = game.id
        self.betType = betType
        self.selection = selection
        self.odds = odds
        self.winProbability = winProbability
        self.expectedValue = expectedValue
        self.kellyStake = kellyStake
    }
    
    private enum CodingKeys: String, CodingKey {
        case gameId, betType, selection, odds, winProbability, expectedValue, kellyStake
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameId = try container.decode(String.self, forKey: .gameId)
        betType = try container.decode(BetType.self, forKey: .betType)
        selection = try container.decode(String.self, forKey: .selection)
        odds = try container.decode(Double.self, forKey: .odds)
        winProbability = try container.decode(Double.self, forKey: .winProbability)
        expectedValue = try container.decode(Double.self, forKey: .expectedValue)
        kellyStake = try container.decode(Double.self, forKey: .kellyStake)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameId, forKey: .gameId)
        try container.encode(betType, forKey: .betType)
        try container.encode(selection, forKey: .selection)
        try container.encode(odds, forKey: .odds)
        try container.encode(winProbability, forKey: .winProbability)
        try container.encode(expectedValue, forKey: .expectedValue)
        try container.encode(kellyStake, forKey: .kellyStake)
    }
    
    public enum BetType: String, Codable {
        case spread
        case playerProp
    }
}

public struct OddsData {
    public let bookmaker: String
    public let odds: Double
    public let market: String
    public let selection: String
    
    public init(bookmaker: String, odds: Double, market: String, selection: String) {
        self.bookmaker = bookmaker
        self.odds = odds
        self.market = market
        self.selection = selection
    }
}

public struct PlayerStats {
    public let playerName: String
    public let team: SportsTeam
    public let lastNGames: [GameStats]
    public let seasonAverages: GameStats
    public let injuryStatus: String?
    
    public struct GameStats {
        public let points: Double
        public let rebounds: Double
        public let assists: Double
        public let minutes: Double
        public let date: Date
    }
}

public struct TeamStats {
    public let teamName: String
    public let lastNGames: [GameStats]
    public let seasonAverages: GameStats
    public let pace: Double
    
    public struct GameStats {
        public let points: Double
        public let pointsAllowed: Double
        public let pace: Double
        public let date: Date
    }
} 