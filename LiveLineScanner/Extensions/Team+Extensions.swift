import Foundation
import CoreData

extension Team {
    // MARK: - Computed Properties
    
    var betCount: Int {
        (bets?.count ?? 0)
    }
    
    var activeBets: [Bet] {
        bets?.allObjects.compactMap { bet in
            let bet = bet as! Bet
            return bet.betStatus == .open ? bet : nil
        } ?? []
    }
    
    var settledBets: [Bet] {
        bets?.allObjects.compactMap { bet in
            let bet = bet as! Bet
            return bet.betStatus != .open ? bet : nil
        } ?? []
    }
    
    var totalWagered: Decimal {
        (bets?.allObjects as? [Bet])?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
    }
    
    var netProfit: Decimal {
        (settledBets.reduce(Decimal(0)) { sum, bet in
            if bet.betStatus == .won {
                return sum + (bet.payout ?? 0)
            } else if bet.betStatus == .lost {
                return sum - bet.amount
            }
            return sum
        })
    }
    
    var winRate: Double {
        let wonBets = settledBets.filter { $0.betStatus == .won }.count
        let totalSettled = settledBets.count
        guard totalSettled > 0 else { return 0 }
        return Double(wonBets) / Double(totalSettled)
    }
    
    // MARK: - Convenience Methods
    
    static func create(in context: NSManagedObjectContext,
                      name: String,
                      sport: Sport) -> Team {
        let team = Team(context: context)
        team.id = UUID()
        team.name = name
        team.sport = sport
        return team
    }
    
    static func fetch(in context: NSManagedObjectContext,
                     name: String,
                     sport: Sport) -> Team? {
        let request = NSFetchRequest<Team>(entityName: "Team")
        request.predicate = NSPredicate(format: "name == %@ AND sport == %@", name, sport)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    static func fetchOrCreate(in context: NSManagedObjectContext,
                            name: String,
                            sport: Sport) -> Team {
        if let existing = fetch(in: context, name: name, sport: sport) {
            return existing
        }
        return create(in: context, name: name, sport: sport)
    }
} 