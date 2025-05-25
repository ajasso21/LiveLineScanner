import Foundation
import CoreData

extension BankrollTransaction {
    // MARK: - Enums
    
    enum TransactionType: String {
        case deposit = "Deposit"
        case withdrawal = "Withdrawal"
        case betWin = "Bet Win"
        case betLoss = "Bet Loss"
    }
    
    // MARK: - Computed Properties
    
    var transactionType: TransactionType {
        get {
            TransactionType(rawValue: type ?? TransactionType.deposit.rawValue) ?? .deposit
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount ?? 0) ?? "$0.00"
    }
    
    @objc var isDeposit: Bool {
        type == TransactionType.deposit.rawValue || type == TransactionType.betWin.rawValue
    }
    
    @objc var isWithdrawal: Bool {
        type == TransactionType.withdrawal.rawValue || type == TransactionType.betLoss.rawValue
    }
    
    // MARK: - Convenience Methods
    
    @nonobjc static func create(in context: NSManagedObjectContext,
                      amount: Decimal,
                      type: TransactionType,
                      notes: String? = nil) -> BankrollTransaction {
        let transaction = BankrollTransaction(context: context)
        transaction.id = UUID()
        transaction.amount = amount as NSDecimalNumber
        transaction.type = type.rawValue
        transaction.createdAt = Date()
        transaction.notes = notes
        return transaction
    }
    
    @nonobjc static func createDeposit(in context: NSManagedObjectContext,
                            amount: Decimal,
                            notes: String? = nil) -> BankrollTransaction {
        return create(in: context, amount: amount, type: .deposit, notes: notes)
    }
    
    @nonobjc static func createWithdrawal(in context: NSManagedObjectContext,
                               amount: Decimal,
                               notes: String? = nil) -> BankrollTransaction {
        return create(in: context, amount: amount, type: .withdrawal, notes: notes)
    }
    
    @nonobjc static func createBetResult(in context: NSManagedObjectContext,
                              amount: Decimal,
                              isWin: Bool,
                              notes: String? = nil) -> BankrollTransaction {
        return create(in: context,
                     amount: amount,
                     type: isWin ? .betWin : .betLoss,
                     notes: notes)
    }
} 