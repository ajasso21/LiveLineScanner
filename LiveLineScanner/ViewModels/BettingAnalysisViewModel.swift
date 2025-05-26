import Foundation

@MainActor
class BettingAnalysisViewModel: ObservableObject {
    private let oddsService: OddsService
    private let analysisService: BettingAnalysisService
    
    @Published var selectedGame: SportsGame?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(oddsService: OddsService, analysisService: BettingAnalysisService) {
        self.oddsService = oddsService
        self.analysisService = analysisService
    }
    
    func analyzeGame(_ game: SportsGame) async {
        isLoading = true
        error = nil
        
        do {
            // Fetch odds for the game
            let odds = try await oddsService.fetchPrematchOdds(for: game)
            
            // Fetch player props if available
            let playerProps = try? await oddsService.fetchPlayerProps(for: game)
            
            // Combine all odds
            let allOdds = odds + (playerProps ?? [])
            
            // Fetch team stats
            let teamStats = try await fetchTeamStats(for: game)
            
            // Fetch player stats
            let playerStats = try await fetchPlayerStats(for: game)
            
            // Analyze the game
            let analysis = try await analysisService.analyzeGame(
                game: game,
                odds: allOdds,
                playerStats: playerStats,
                teamStats: teamStats
            )
            
            // Update the game with the analysis
            var updatedGame = game
            updatedGame.analysis = analysis
            selectedGame = updatedGame
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func fetchTeamStats(for game: SportsGame) async throws -> [TeamStats] {
        // TODO: Implement team stats fetching
        return []
    }
    
    private func fetchPlayerStats(for game: SportsGame) async throws -> [PlayerStats] {
        // TODO: Implement player stats fetching
        return []
    }
    
    func formatAnalysis(_ analysis: [BettingAnalysis]) -> String {
        var result = ""
        for bet in analysis {
            result += "Bet Type: \(bet.betType.rawValue)\n"
            result += "Selection: \(bet.selection)\n"
            result += "Odds: \(String(format: "%.1f", bet.odds))\n"
            result += "Win Probability: \(String(format: "%.1f", bet.winProbability * 100))%\n"
            result += "Expected Value: \(String(format: "%.1f", bet.expectedValue * 100))%\n"
            result += "Kelly Stake: \(String(format: "%.1f", bet.kellyStake * 100))%\n\n"
        }
        return result
    }
} 