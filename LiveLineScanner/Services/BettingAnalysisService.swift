import Foundation

public class BettingAnalysisService {
    private let openAIService: OpenAIService
    
    public init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    public func analyzeGame(game: SportsGame, odds: [OddsData], playerStats: [PlayerStats], teamStats: [TeamStats]) async throws -> [BettingAnalysis] {
        // Prepare the prompt for ChatGPT
        let prompt = createAnalysisPrompt(game: game, odds: odds, playerStats: playerStats, teamStats: teamStats)
        
        // Get analysis from ChatGPT
        let analysis = try await openAIService.analyzeBettingOpportunities(prompt: prompt)
        
        // Parse and return the analysis
        return parseAnalysis(analysis)
    }
    
    private func createAnalysisPrompt(game: SportsGame, odds: [OddsData], playerStats: [PlayerStats], teamStats: [TeamStats]) -> String {
        var prompt = """
        Analyze the following game and betting opportunities:
        
        Game: \(game.home.name) vs \(game.away.name)
        Date: \(game.scheduled)
        
        Available Odds:
        """
        
        // Add odds information
        for odd in odds {
            prompt += "\n- \(odd.bookmaker): \(odd.market) - \(odd.selection) @ \(odd.odds)"
        }
        
        // Add team stats
        prompt += "\n\nTeam Statistics:"
        for team in teamStats {
            prompt += "\n\(team.teamName):"
            prompt += "\n- Season Pace: \(team.pace)"
            prompt += "\n- Last 5 Games Average: \(team.seasonAverages.points) points, \(team.seasonAverages.pointsAllowed) points allowed"
        }
        
        // Add player stats
        prompt += "\n\nPlayer Statistics:"
        for player in playerStats {
            prompt += "\n\(player.playerName) (\(player.team.name)):"
            prompt += "\n- Season Average: \(player.seasonAverages.points) points, \(player.seasonAverages.rebounds) rebounds, \(player.seasonAverages.assists) assists"
            if let injury = player.injuryStatus {
                prompt += "\n- Injury Status: \(injury)"
            }
        }
        
        prompt += """
        
        Please analyze this data and provide:
        1. True probability estimates for each bet
        2. Expected value calculations
        3. Kelly criterion stake recommendations
        
        Format the response as a JSON array of betting opportunities, each containing:
        - betType (spread/playerProp)
        - selection
        - odds
        - winProbability
        - expectedValue
        - kellyStake
        """
        
        return prompt
    }
    
    private func parseAnalysis(_ analysis: String) -> [BettingAnalysis] {
        guard let data = analysis.data(using: .utf8) else { return [] }
        
        do {
            let decoder = JSONDecoder()
            let opportunities = try decoder.decode([BettingOpportunity].self, from: data)
            return opportunities.map { opportunity in
                BettingAnalysis(
                    game: opportunity.game,
                    betType: opportunity.betType == "spread" ? .spread : .playerProp,
                    selection: opportunity.selection,
                    odds: opportunity.odds,
                    winProbability: opportunity.winProbability,
                    expectedValue: opportunity.expectedValue,
                    kellyStake: opportunity.kellyStake
                )
            }
        } catch {
            print("Error parsing analysis: \(error)")
            return []
        }
    }
}

// Temporary structure for JSON decoding
private struct BettingOpportunity: Codable {
    let betType: String
    let selection: String
    let odds: Double
    let winProbability: Double
    let expectedValue: Double
    let kellyStake: Double
    let game: SportsGame
    
    enum CodingKeys: String, CodingKey {
        case betType
        case selection
        case odds
        case winProbability
        case expectedValue
        case kellyStake
        case game
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let betTypeString = try container.decode(String.self, forKey: .betType)
        betType = betTypeString
        selection = try container.decode(String.self, forKey: .selection)
        odds = try container.decode(Double.self, forKey: .odds)
        winProbability = try container.decode(Double.self, forKey: .winProbability)
        expectedValue = try container.decode(Double.self, forKey: .expectedValue)
        kellyStake = try container.decode(Double.self, forKey: .kellyStake)
        game = try container.decode(SportsGame.self, forKey: .game)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(betType, forKey: .betType)
        try container.encode(selection, forKey: .selection)
        try container.encode(odds, forKey: .odds)
        try container.encode(winProbability, forKey: .winProbability)
        try container.encode(expectedValue, forKey: .expectedValue)
        try container.encode(kellyStake, forKey: .kellyStake)
        try container.encode(game, forKey: .game)
    }
} 
