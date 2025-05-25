import Foundation
import CoreData

extension Sport {
    // MARK: - Computed Properties
    
    @objc var betCount: Int {
        (bets?.count ?? 0)
    }
    
    var activeBets: [Bet] {
        bets?.allObjects.compactMap { bet in
            let bet = bet as! Bet
            return bet.status == Bet.Status.open.rawValue ? bet : nil
        } ?? []
    }
    
    var settledBets: [Bet] {
        bets?.allObjects.compactMap { bet in
            let bet = bet as! Bet
            return bet.status != Bet.Status.open.rawValue ? bet : nil
        } ?? []
    }
    
    var totalWagered: Decimal {
        (bets?.allObjects as? [Bet])?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
    }
    
    var netProfit: Decimal {
        (settledBets.reduce(Decimal(0)) { sum, bet in
            if bet.status == Bet.Status.won.rawValue {
                return sum + (bet.payout ?? 0)
            } else if bet.status == Bet.Status.lost.rawValue {
                return sum - bet.amount
            }
            return sum
        })
    }
    
    var winRate: Double {
        let wonBets = settledBets.filter { $0.status == Bet.Status.won.rawValue }.count
        let totalSettled = settledBets.count
        guard totalSettled > 0 else { return 0 }
        return Double(wonBets) / Double(totalSettled)
    }
    
    // MARK: - Convenience Methods
    
    @nonobjc static func create(in context: NSManagedObjectContext,
                      name: String) -> Sport {
        let sport = Sport(context: context)
        sport.id = UUID()
        sport.name = name
        return sport
    }
    
    @nonobjc static func fetch(in context: NSManagedObjectContext,
                     name: String) -> Sport? {
        let request = Sport.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    @nonobjc static func fetchOrCreate(in context: NSManagedObjectContext,
                            name: String) -> Sport {
        if let existing = fetch(in: context, name: name) {
            return existing
        }
        return create(in: context, name: name)
    }
} 