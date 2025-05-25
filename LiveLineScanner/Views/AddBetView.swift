import SwiftUI
import CoreData

struct AddBetView: View {
    @Environment(\.dismiss) private var dismiss
    let context: NSManagedObjectContext
    
    @State private var selectedSport: Sport?
    @State private var selectedTeam: Team?
    @State private var amount: Decimal = 0
    @State private var odds: Double = 0
    @State private var betType: Bet.BetType = .moneyline
    @State private var notes: String = ""
    @State private var showingSportPicker = false
    @State private var showingTeamPicker = false
    @State private var errorMessage: String?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Sport.name, ascending: true)],
        animation: .default)
    private var sports: FetchedResults<Sport>
    
    private var teams: [Team] {
        guard let sport = selectedSport else { return [] }
        return (sport.teams?.allObjects as? [Team] ?? []).sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    private var isFormValid: Bool {
        amount > 0 && odds != 0 && selectedSport != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Sport & Team Selection
                Section("Game Details") {
                    Button(action: { showingSportPicker = true }) {
                        HStack {
                            Text("Sport")
                            Spacer()
                            Text(selectedSport?.name ?? "Select Sport")
                                .foregroundColor(selectedSport == nil ? .secondary : .primary)
                        }
                    }
                    
                    if !teams.isEmpty {
                        Button(action: { showingTeamPicker = true }) {
                            HStack {
                                Text("Team")
                                Spacer()
                                Text(selectedTeam?.name ?? "Select Team")
                                    .foregroundColor(selectedTeam == nil ? .secondary : .primary)
                            }
                        }
                    }
                }
                
                // MARK: - Bet Details
                Section("Bet Details") {
                    Picker("Type", selection: $betType) {
                        ForEach(Bet.BetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Odds")
                        Spacer()
                        TextField("0", value: $odds, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // MARK: - Additional Info
                Section("Additional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                // MARK: - Potential Payout
                if amount > 0 && odds != 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Potential Payout")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(calculatePotentialPayout().formatted(.currency(code: "USD")))
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Place") {
                        placeBet()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingSportPicker) {
                SportPickerView(sports: Array(sports), selectedSport: $selectedSport)
            }
            .sheet(isPresented: $showingTeamPicker) {
                TeamPickerView(teams: teams, selectedTeam: $selectedTeam)
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
    
    private func calculatePotentialPayout() -> Decimal {
        if odds >= 0 {
            return amount * (Decimal(odds) / 100)
        } else {
            return amount / (Decimal(abs(odds)) / 100)
        }
    }
    
    private func placeBet() {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        let bet = Bet.create(
            in: context,
            amount: amount,
            odds: odds,
            type: betType,
            sport: selectedSport,
            team: selectedTeam,
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save bet: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views
struct SportPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let sports: [Sport]
    @Binding var selectedSport: Sport?
    
    var body: some View {
        NavigationStack {
            List(sports, id: \.id) { sport in
                Button {
                    selectedSport = sport
                    dismiss()
                } label: {
                    HStack {
                        Text(sport.name ?? "")
                        Spacer()
                        if sport == selectedSport {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TeamPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let teams: [Team]
    @Binding var selectedTeam: Team?
    
    var body: some View {
        NavigationStack {
            List(teams, id: \.id) { team in
                Button {
                    selectedTeam = team
                    dismiss()
                } label: {
                    HStack {
                        Text(team.name ?? "")
                        Spacer()
                        if team == selectedTeam {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddBetView(context: PersistenceController.preview.container.viewContext)
} 