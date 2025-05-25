import SwiftUI

// MARK: - Models
struct OddsOutcomeInfo: Identifiable {
    let id = UUID()
    let outcome: String
    let book: String
    let price: Double
    var impliedProb: Double { 1.0 / price }
}

struct ArbitrageOpportunity: Identifiable {
    let id = UUID()
    let event: String
    let market: String
    let outcomes: [OddsOutcomeInfo]
    let arbitrageMargin: Double  // sumInverse <1, margin = 1 - sumInverse
}

// MARK: - ViewModel
@MainActor
class ArbitrageViewModel: ObservableObject {
    @Published var arbitrages: [ArbitrageOpportunity] = []
    @Published var bankroll: String = "100"
    @Published var trueProbInputs: [String: String] = [:]
    
    var availableLines: [OddsLine] {
        oddsVM.bestLines
    }
    
    private let oddsVM: OddsComparisonViewModel
    
    init(oddsVM: OddsComparisonViewModel) {
        self.oddsVM = oddsVM
    }
    
    // MARK: - Arbitrage Scanning
    func scanArbitrage() {
        var ops: [ArbitrageOpportunity] = []
        
        // Group by market (assuming each market represents a unique event)
        let grouped = Dictionary(grouping: availableLines) { $0.market }
        
        for (market, lines) in grouped {
            // Convert lines to outcome info
            let infos = lines.map { 
                OddsOutcomeInfo(
                    outcome: $0.outcome,
                    book: $0.bestBook,
                    price: $0.bestPrice
                )
            }
            
            // Calculate arbitrage opportunity
            let sumInv = infos.map { $0.impliedProb }.reduce(0, +)
            if sumInv < 1 {
                let margin = 1 - sumInv
                let op = ArbitrageOpportunity(
                    event: market,
                    market: market,
                    outcomes: infos,
                    arbitrageMargin: margin
                )
                ops.append(op)
            }
        }
        
        arbitrages = ops
    }
    
    // MARK: - Betting Calculations
    
    /// Kelly fraction = (b * p - (1 - p)) / b
    /// where b = price - 1 (decimal odds converted to fractional)
    /// and p = true probability
    func kellyFraction(price: Double, trueProb: Double) -> Double {
        let b = price - 1
        let p = trueProb
        return (b * p - (1 - p)) / b
    }
    
    /// Value index = true probability - implied probability
    /// Positive value indicates potential edge
    func valueIndex(impliedProb: Double, trueProb: Double) -> Double {
        trueProb - impliedProb
    }
}

// MARK: - Main View
struct ArbitrageView: View {
    @EnvironmentObject private var oddsVM: OddsComparisonViewModel
    @StateObject private var vm: ArbitrageViewModel
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss
    
    init(oddsVM: OddsComparisonViewModel? = nil) {
        // If oddsVM is provided directly, use it; otherwise it will be provided via environmentObject
        let viewModel = oddsVM ?? OddsComparisonViewModel()
        _vm = StateObject(wrappedValue: ArbitrageViewModel(oddsVM: viewModel))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Input Controls
                HStack {
                    TextField("Bankroll", text: $vm.bankroll)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    
                    Button("Scan Arbitrage") {
                        vm.scanArbitrage()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .padding()
                
                // Results List
                List(vm.arbitrages) { arb in
                    Section(header: Text("Market: \(arb.market)")) {
                        ForEach(arb.outcomes) { info in
                            HStack {
                                // Outcome Info
                                VStack(alignment: .leading) {
                                    Text(info.outcome)
                                    Text(info.book)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Calculations
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f", info.price))
                                    Text(String(format: "Imp: %.1f%%", info.impliedProb * 100))
                                        .font(.caption2)
                                    
                                    // Kelly calculation if true prob available
                                    if let pText = vm.trueProbInputs[info.outcome],
                                       let p = Double(pText) {
                                        let k = vm.kellyFraction(price: info.price, trueProb: p)
                                        Text(String(format: "K: %.2f", k))
                                            .font(.caption2)
                                            .foregroundColor(k > 0 ? .green : .red)
                                    }
                                }
                            }
                        }
                        
                        // Arbitrage Margin
                        Text(String(format: "Arb Margin: %.2f%%", arb.arbitrageMargin * 100))
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Arbitrage Scanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(vm: vm)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var vm: ArbitrageViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("True Probabilities")) {
                    ForEach(vm.arbitrages.flatMap { $0.outcomes }, id: \.id) { info in
                        HStack {
                            Text(info.outcome)
                            Spacer()
                            TextField("True%", text: Binding(
                                get: { vm.trueProbInputs[info.outcome] ?? "" },
                                set: { vm.trueProbInputs[info.outcome] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ArbitrageView(oddsVM: OddsComparisonViewModel())
} 