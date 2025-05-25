// ParlayBuilderView.swift
// Parlay Builder & EV Calculator with drag-and-drop and EV vs vig

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Models
struct Selection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let decimalOdds: Double // e.g. 2.5 for +150
}

// MARK: - ViewModel
class ParlayViewModel: ObservableObject {
    @Published var available: [Selection] = []
    @Published var parlay: [Selection] = []
    @Published var stake: String = "10"

    init() {
        // Sample data; in real app, load from odds feed
        available = [
            Selection(name: "Team A ML", decimalOdds: 1.8),
            Selection(name: "Team B Spread -3.5", decimalOdds: 1.9),
            Selection(name: "Player X Over 25.5 pts", decimalOdds: 2.1),
            Selection(name: "Team C Total Over 210", decimalOdds: 1.95)
        ]
    }

    var combinedOdds: Double {
        parlay.map { $0.decimalOdds }.reduce(1.0, *)
    }

    var impliedProbability: Double {
        1.0 / combinedOdds
    }

    var vigAdjustedEV: Double {
        guard let s = Double(stake) else { return 0 }
        let payout = s * combinedOdds
        let expectedValue = impliedProbability * payout - (1 - impliedProbability) * s
        return expectedValue
    }
}

// MARK: - View
struct ParlayBuilderView: View {
    @StateObject private var vm = ParlayViewModel()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack {
                        Text("Available Picks")
                            .font(.headline)
                        List(vm.available) { sel in
                            Text(sel.name)
                                .onDrag { NSItemProvider(object: sel.name as NSString) }
                                .listRowBackground(Color.themeCard)
                        }
                    }
                    VStack {
                        Text("Your Parlay")
                            .font(.headline)
                        List(vm.parlay) { sel in
                            Text(sel.name)
                                .onDrag { NSItemProvider(object: sel.name as NSString) }
                                .listRowBackground(Color.themeCard)
                        }
                        .onDrop(of: [UTType.text], delegate: ParlayDropDelegate(vm: vm))
                    }
                }
                .frame(height: 300)

                HStack {
                    Text("Stake:")
                    TextField("Stake", text: $vm.stake)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                .padding()
                .background(Color.themeCard)
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: "Combined Odds: %.2f", vm.combinedOdds))
                    Text(String(format: "Implied Probability: %.1f%%", vm.impliedProbability * 100))
                    Text(String(format: "Expected Value (vs vig): %.2f", vm.vigAdjustedEV))
                        .foregroundColor(vm.vigAdjustedEV >= 0 ? Color.themeUp : Color.themeDown)
                }
                .padding()
                .background(Color.themeCard)
                .cornerRadius(10)

                Spacer()
            }
            .navigationTitle("Parlay Builder")
            .background(Color.themeBackground)
        }
    }
}

// MARK: - Drop Delegate
struct ParlayDropDelegate: DropDelegate {
    let vm: ParlayViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [UTType.text]).first else { return false }
        item.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, error) in
            DispatchQueue.main.async {
                if let name = data as? Data,
                   let str = String(data: name, encoding: .utf8),
                   let sel = vm.available.first(where: { $0.name == str }) {
                    if !vm.parlay.contains(sel) {
                        vm.parlay.append(sel)
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Preview
struct ParlayBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        ParlayBuilderView()
    }
} 