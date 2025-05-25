import Foundation
import CoreData

extension Bet {
    // MARK: - Enums
    
    enum Status: String {
        case open = "Open"
        case won = "Won"
        case lost = "Lost"
        case pushed = "Pushed"
        case cancelled = "Cancelled"
    }
    
    enum BetType: String {
        case moneyline = "Moneyline"
        case spread = "Spread"
        case overUnder = "Over/Under"
        case prop = "Prop"
        case parlay = "Parlay"
    }
    
    // MARK: - Computed Properties
    
    var betStatus: Status {
        get {
            Status(rawValue: status ?? Status.open.rawValue) ?? .open
        }
        set {
            status = newValue.rawValue
        }
    }
    
    var betType: BetType {
        get {
            BetType(rawValue: type ?? BetType.moneyline.rawValue) ?? .moneyline
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    var formattedOdds: String {
        if odds >= 0 {
            return "+\(Int(odds))"
        }
        return "\(Int(odds))"
    }
    
    var potentialPayout: Decimal {
        if odds >= 0 {
            return amount * (Decimal(odds) / 100)
        } else {
            return amount / (Decimal(abs(odds)) / 100)
        }
    }
    
    var formattedPotentialPayout: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: potentialPayout)) ?? "$0.00"
    }
    
    var isSettled: Bool {
        settledAt != nil
    }
    
    var durationOpen: TimeInterval? {
        guard let settled = settledAt else { return nil }
        return settled.timeIntervalSince(placedAt ?? Date())
    }
    
    // MARK: - Convenience Methods
    
    static func create(in context: NSManagedObjectContext,
                      amount: Decimal,
                      odds: Double,
                      type: BetType,
                      sport: Sport? = nil,
                      team: Team? = nil,
                      notes: String? = nil) -> Bet {
        let bet = Bet(context: context)
        bet.id = UUID()
        bet.amount = amount
        bet.odds = odds
        bet.type = type.rawValue
        bet.status = Status.open.rawValue
        bet.createdAt = Date()
        bet.placedAt = Date()
        bet.sport = sport
        bet.team = team
        bet.notes = notes
        return bet
    }
    
    func settle(as status: Status, withPayout payout: Decimal? = nil) {
        self.betStatus = status
        self.settledAt = Date()
        self.payout = payout
    }
    
    func cancel() {
        settle(as: .cancelled)
    }
} 