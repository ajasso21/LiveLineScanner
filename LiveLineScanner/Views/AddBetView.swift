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
        
        // Get all teams from the sport
        let allTeams = sport.teams?.allObjects as? [Team] ?? []
        
        // Sort teams by name
        return allTeams.sorted { team1, team2 in
            let name1 = team1.name ?? ""
            let name2 = team2.name ?? ""
            return name1 < name2
        }
    }
    
    private var isFormValid: Bool {
        // Check if amount is valid
        let hasValidAmount = amount > 0
        
        // Check if odds are valid
        let hasValidOdds = odds != 0
        
        // Check if sport is selected
        let hasSelectedSport = selectedSport != nil
        
        // Combine all conditions
        let isValid = hasValidAmount && hasValidOdds && hasSelectedSport
        
        return isValid
    }
    
    var body: some View {
        NavigationStack {
            Form {
                gameDetailsSection
                betDetailsSection
                additionalInfoSection
                potentialPayoutSection
            }
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingSportPicker) {
                BetSportPickerView(sports: Array(sports), selectedSport: $selectedSport)
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
    
    private var gameDetailsSection: some View {
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
    }
    
    private var betDetailsSection: some View {
        Section("Bet Details") {
            Picker("Type", selection: $betType) {
                ForEach(Bet.BetType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
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
    }
    
    private var additionalInfoSection: some View {
        Section("Additional Information") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
        }
    }
    
    private var potentialPayoutSection: some View {
        Group {
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
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
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
        
        _ = Bet.create(
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
struct BetSportPickerView: View {
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