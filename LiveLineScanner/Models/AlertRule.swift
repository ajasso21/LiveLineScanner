import Foundation

struct AlertRule: Identifiable, Codable {
    enum RuleType: String, Codable, CaseIterable {
        case parlayEV = "Parlay EV"
        case moneyline = "Moneyline"
        case arbitrage = "Arbitrage"
        case valueIndex = "Value Index"
    }
    
    let id: UUID
    var type: RuleType
    var threshold: Double
    var enabled: Bool
    var lastFired: Date?
    var snoozeUntil: Date?
    
    var isSnoozing: Bool {
        guard let snoozeUntil = snoozeUntil else { return false }
        return Date() < snoozeUntil
    }
    
    var displayThreshold: String {
        switch type {
        case .parlayEV, .arbitrage, .valueIndex:
            return "\(Int(threshold * 100))%"
        case .moneyline:
            return String(format: "%.2f", threshold)
        }
    }
} 