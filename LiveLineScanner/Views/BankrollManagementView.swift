import SwiftUI
import CoreData

struct BankrollManagementView: View {
    @Environment(\.dismiss) private var dismiss
    let context: NSManagedObjectContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BankrollTransaction.createdAt, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<BankrollTransaction>
    
    @State private var showingAddTransaction = false
    @State private var transactionType: BankrollTransaction.TransactionType = .deposit
    @State private var amount: Decimal = 0
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    private var currentBankroll: Decimal {
        transactions.reduce(Decimal(0)) { sum, transaction in
            if transaction.isDeposit {
                return sum + transaction.amount
            } else {
                return sum - transaction.amount
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Current Balance
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Balance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(currentBankroll.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                
                // MARK: - Quick Actions
                Section {
                    HStack(spacing: 20) {
                        Button {
                            transactionType = .deposit
                            showingAddTransaction = true
                        } label: {
                            QuickActionButton(
                                title: "Deposit",
                                systemImage: "plus.circle.fill",
                                color: .green
                            )
                        }
                        
                        Button {
                            transactionType = .withdrawal
                            showingAddTransaction = true
                        } label: {
                            QuickActionButton(
                                title: "Withdraw",
                                systemImage: "minus.circle.fill",
                                color: .red
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
                
                // MARK: - Transaction History
                Section("Transaction History") {
                    if transactions.isEmpty {
                        ContentUnavailableView(
                            "No Transactions",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Your transaction history will appear here")
                        )
                    } else {
                        ForEach(transactions) { transaction in
                            TransactionRowView(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("Bankroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(
                    context: context,
                    transactionType: transactionType
                )
            }
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    let context: NSManagedObjectContext
    let transactionType: BankrollTransaction.TransactionType
    
    @State private var amount: Decimal = 0
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        amount > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(transactionType == .deposit ? "Add Deposit" : "Add Withdrawal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func saveTransaction() {
        guard isFormValid else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        let transaction = BankrollTransaction.create(
            in: context,
            amount: amount,
            type: transactionType,
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save transaction: \(error.localizedDescription)"
        }
    }
}

struct TransactionRowView: View {
    let transaction: BankrollTransaction
    
    var body: some View {
        HStack {
            // Icon and Type
            VStack(alignment: .leading) {
                Image(systemName: transaction.isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(transaction.isDeposit ? .green : .red)
                    .font(.title2)
                Text(transaction.transactionType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Details
            VStack(alignment: .leading) {
                if let notes = transaction.notes {
                    Text(notes)
                        .font(.subheadline)
                }
                Text(transaction.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Amount
            Text(transaction.formattedAmount)
                .font(.headline)
                .foregroundColor(transaction.isDeposit ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BankrollManagementView(context: PersistenceController.preview.container.viewContext)
} 