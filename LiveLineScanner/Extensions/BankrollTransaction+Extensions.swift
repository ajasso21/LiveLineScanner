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
    
    @objc var transactionType: TransactionType {
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
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    @objc var isDeposit: Bool {
        transactionType == .deposit || transactionType == .betWin
    }
    
    @objc var isWithdrawal: Bool {
        transactionType == .withdrawal || transactionType == .betLoss
    }
    
    // MARK: - Convenience Methods
    
    @nonobjc static func create(in context: NSManagedObjectContext,
                      amount: Decimal,
                      type: TransactionType,
                      notes: String? = nil) -> BankrollTransaction {
        let transaction = BankrollTransaction(context: context)
        transaction.id = UUID()
        transaction.amount = amount
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