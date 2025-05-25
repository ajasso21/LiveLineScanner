import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = APIConfig.shared.apiKey
    private let vm: ArbitrageViewModel?
    
    init(vm: ArbitrageViewModel? = nil) {
        self.vm = vm
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Configuration")) {
                    SecureField("API Key", text: $apiKey)
                        .onChange(of: apiKey) { oldValue, newValue in
                            APIConfig.shared.apiKey = newValue
                        }
                }
                
                if let vm = vm {
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
    SettingsView(vm: ArbitrageViewModel(oddsVM: OddsComparisonViewModel()))
} 