import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    let game: Game
    let quotes: [OddsQuote]
    let metrics: ChatGPTMetrics
    @Published var parlays: [Parlay] = []
    @Published var isExpanded = false
    
    init(game: Game, quotes: [OddsQuote], metrics: ChatGPTMetrics) {
        self.game = game
        self.quotes = quotes
        self.metrics = metrics
    }
    
    func computeParlaysAndKelly() {
        let implied = quotes.map { 1/$0.oddsDecimal }
        let evs = quotes.map { metrics.trueProb - (1 / $0.oddsDecimal) }
        // Build parlays of length 1,2,3...
        var list: [Parlay] = []
        for k in 1...3 {
            combinations(quotes, k).forEach { combo in
                let combinedOdds = combo.map { $0.oddsDecimal }.reduce(1, *)
                let impliedCombo = combo.map { 1/$0.oddsDecimal }.reduce(1, *)
                let ev = metrics.trueProb - (1/combinedOdds)
                let kelly = (combinedOdds - 1)*metrics.trueProb - (1-metrics.trueProb)
                    / (combinedOdds - 1)
                list.append(Parlay(legs: combo, ev: ev, kelly: kelly))
            }
        }
        parlays = list.sorted { $0.ev > $1.ev }
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: game.startTime)
    }
}

// Helper
func combinations<T>(_ array: [T], _ k: Int) -> [[T]] {
    if k == 0 { return [[]] }
    guard let first = array.first else { return [] }
    let sub = Array(array.dropFirst())
    let withFirst = combinations(sub, k-1).map { [first] + $0 }
    let without = combinations(sub, k)
    return withFirst + without
}

struct Parlay: Identifiable {
    let id = UUID()
    let legs: [OddsQuote]
    let ev: Double
    let kelly: Double
    
    var formattedEV: String {
        String(format: "%.1f%%", ev * 100)
    }
    
    var formattedKelly: String {
        String(format: "%.1f%%", kelly * 100)
    }
    
    var combinedOdds: Double {
        legs.map { $0.oddsDecimal }.reduce(1, *)
    }
    
    var formattedOdds: String {
        let american = combinedOdds >= 2.0 ? 
            Int((combinedOdds - 1) * 100) :
            Int(-100 / (combinedOdds - 1))
        let prefix = american > 0 ? "+" : ""
        return "\(prefix)\(american)"
    }
} 