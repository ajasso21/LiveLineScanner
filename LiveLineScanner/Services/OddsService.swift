import Foundation

@MainActor
class OddsService {
    private let session = URLSession.shared
    
    func fetchOdds(for gameID: String) async throws -> [OddsQuote] {
        // In a real app, you would fetch from actual bookmaker APIs
        // For now, we'll simulate some odds
        return [
            OddsQuote(bookmaker: "FanDuel",
                     market: "moneyline",
                     selection: "Home",
                     oddsDecimal: 1.85),
            OddsQuote(bookmaker: "FanDuel",
                     market: "moneyline",
                     selection: "Away",
                     oddsDecimal: 2.10),
            OddsQuote(bookmaker: "DraftKings",
                     market: "moneyline",
                     selection: "Home",
                     oddsDecimal: 1.90),
            OddsQuote(bookmaker: "DraftKings",
                     market: "moneyline",
                     selection: "Away",
                     oddsDecimal: 2.05)
        ]
    }
} 