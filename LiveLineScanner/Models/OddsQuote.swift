import Foundation

struct OddsQuote: Identifiable {
    let id = UUID()
    let bookmaker: String
    let market: String  // "moneyline", "spread", "total", etc.
    let selection: String
    let oddsDecimal: Double
    
    var oddsAmerican: Int {
        if oddsDecimal >= 2.0 {
            return Int((oddsDecimal - 1) * 100)
        } else {
            return Int(-100 / (oddsDecimal - 1))
        }
    }
    
    var formattedOdds: String {
        let prefix = oddsAmerican > 0 ? "+" : ""
        return "\(prefix)\(oddsAmerican)"
    }
} 