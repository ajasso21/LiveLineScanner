import SwiftUI
import CoreData

struct BetTrackerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bet.placedAt, ascending: false)],
        predicate: NSPredicate(format: "status == %@", Bet.Status.open.rawValue),
        animation: .default)
    private var activeBets: FetchedResults<Bet>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bet.settledAt, ascending: false)],
        predicate: NSPredicate(format: "status != %@", Bet.Status.open.rawValue),
        animation: .default)
    private var settledBets: FetchedResults<Bet>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BankrollTransaction.createdAt, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<BankrollTransaction>
    
    @State private var showingAddBet = false
    @State private var showingBankrollSheet = false
    @State private var selectedTimeFrame: TimeFrame = .allTime
    
    enum TimeFrame: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Summary Cards
                    summarySection
                    
                    // MARK: - Quick Actions
                    quickActionsSection
                    
                    // MARK: - Active Bets
                    activeBetsSection
                    
                    // MARK: - Bet History
                    betHistorySection
                }
                .padding()
            }
            .navigationTitle("Bet Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Button(timeFrame.rawValue) {
                                selectedTimeFrame = timeFrame
                            }
                        }
                    } label: {
                        Label(selectedTimeFrame.rawValue, systemImage: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingAddBet) {
                AddBetView(context: viewContext)
            }
            .sheet(isPresented: $showingBankrollSheet) {
                BankrollManagementView(context: viewContext)
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 15) {
            // Bankroll Card
            SummaryCard(title: "Current Bankroll", value: currentBankroll.formatted(.currency(code: "USD"))) {
                HStack(spacing: 20) {
                    StatItem(title: "Net Profit", value: netProfit.formatted(.currency(code: "USD")), color: netProfit >= 0 ? .green : .red)
                    StatItem(title: "Win Rate", value: "\(Int(winRate * 100))%", color: .blue)
                }
            }
            
            // Performance Card
            SummaryCard(title: "Performance", value: "Active Bets: \(activeBets.count)") {
                HStack(spacing: 20) {
                    StatItem(title: "Total Bets", value: "\(settledBets.count)", color: .purple)
                    StatItem(title: "ROI", value: "\(Int(roi * 100))%", color: roi >= 0 ? .green : .red)
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 20) {
            Button(action: { showingAddBet = true }) {
                QuickActionButton(title: "Place Bet", systemImage: "plus.circle.fill", color: .blue)
            }
            
            Button(action: { showingBankrollSheet = true }) {
                QuickActionButton(title: "Manage Bankroll", systemImage: "dollarsign.circle.fill", color: .green)
            }
        }
    }
    
    // MARK: - Active Bets Section
    private var activeBetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Bets")
                .font(.title2)
                .bold()
            
            if activeBets.isEmpty {
                EmptyStateView(
                    title: "No Active Bets",
                    message: "Your placed bets will appear here",
                    systemImage: "ticket"
                )
            } else {
                ForEach(activeBets) { bet in
                    BetRowView(bet: bet)
                }
            }
        }
    }
    
    // MARK: - Bet History Section
    private var betHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bet History")
                .font(.title2)
                .bold()
            
            if settledBets.isEmpty {
                EmptyStateView(
                    title: "No Settled Bets",
                    message: "Your betting history will appear here",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                ForEach(settledBets) { bet in
                    BetRowView(bet: bet)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var currentBankroll: Decimal {
        transactions.reduce(Decimal(0)) { sum, transaction in
            if transaction.isDeposit {
                return sum + transaction.amount
            } else {
                return sum - transaction.amount
            }
        }
    }
    
    private var netProfit: Decimal {
        settledBets.reduce(Decimal(0)) { sum, bet in
            if bet.betStatus == .won {
                return sum + (bet.payout ?? 0)
            } else if bet.betStatus == .lost {
                return sum - bet.amount
            }
            return sum
        }
    }
    
    private var winRate: Double {
        let wonBets = settledBets.filter { $0.betStatus == .won }.count
        guard !settledBets.isEmpty else { return 0 }
        return Double(wonBets) / Double(settledBets.count)
    }
    
    private var roi: Double {
        let totalWagered = settledBets.reduce(Decimal(0)) { $0 + $1.amount }
        guard totalWagered > 0 else { return 0 }
        return Double(netProfit / totalWagered)
    }
}

// MARK: - Supporting Views
struct SummaryCard<Content: View>: View {
    let title: String
    let value: String
    let content: Content
    
    init(title: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .bold()
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct BetRowView: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bet.team?.name ?? "Unknown Team")
                        .font(.headline)
                    Text(bet.sport?.name ?? "Unknown Sport")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(bet.formattedAmount)
                        .font(.headline)
                    Text(bet.formattedOdds)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if bet.isSettled {
                HStack {
                    Text(bet.betStatus.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if let payout = bet.payout {
                        Text(payout.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .foregroundColor(bet.betStatus == .won ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var statusColor: Color {
        switch bet.betStatus {
        case .won: return .green
        case .lost: return .red
        case .pushed: return .orange
        case .cancelled: return .gray
        default: return .blue
        }
    }
}

#Preview {
    BetTrackerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 