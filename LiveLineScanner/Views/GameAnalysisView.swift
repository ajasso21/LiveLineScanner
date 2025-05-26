import SwiftUI

struct GameAnalysisView: View {
    let game: SportsGame
    @StateObject private var viewModel: BettingAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = false
    
    init(game: SportsGame, viewModel: BettingAnalysisViewModel) {
        self.game = game
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Game Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(game.away.name) @ \(game.home.name)")
                        .font(.title)
                        .bold()
                    
                    Text(game.scheduled, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.isLoading || isAnalyzing {
                    VStack {
                        ProgressView("Analyzing betting opportunities...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    }
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Retry Analysis") {
                            Task {
                                await analyzeGame()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if let analysis = game.analysis {
                    // Betting Opportunities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Betting Opportunities")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(analysis, id: \.selection) { bet in
                            BettingOpportunityCard(bet: bet)
                        }
                    }
                } else {
                    VStack {
                        Text("No betting analysis available")
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Button("Start Analysis") {
                            Task {
                                await analyzeGame()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await analyzeGame()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await analyzeGame()
        }
    }
    
    private func analyzeGame() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        await viewModel.analyzeGame(game)
    }
}

struct BettingOpportunityCard: View {
    let bet: BettingAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bet Type and Selection
            HStack {
                Text(bet.betType.rawValue.capitalized)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("Odds: \(String(format: "%.1f", bet.odds))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(bet.selection)
                .font(.title3)
                .bold()
            
            // Analysis Details
            VStack(alignment: .leading, spacing: 8) {
                AnalysisRow(title: "Win Probability", value: bet.winProbability, format: "%.1f%%")
                AnalysisRow(title: "Expected Value", value: bet.expectedValue, format: "%.1f%%")
                AnalysisRow(title: "Kelly Stake", value: bet.kellyStake, format: "%.1f%%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: Double
    let format: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: format, value * 100))
                .bold()
                .foregroundColor(value > 0 ? .green : .red)
        }
        .font(.subheadline)
    }
}

// Preview provider
struct GameAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let oddsService = OddsService(apiKey: "your-api-key")
        let openAIService = OpenAIService(apiKey: "your-api-key")
        let analysisService = BettingAnalysisService(openAIService: openAIService)
        let viewModel = BettingAnalysisViewModel(oddsService: oddsService, analysisService: analysisService)
        
        let game = SportsGame(
            id: "1",
            home: SportsTeam(id: "1", name: "Home Team", abbreviation: "HOME"),
            away: SportsTeam(id: "2", name: "Away Team", abbreviation: "AWAY"),
            scheduled: Date(),
            status: .scheduled,
            league: .nba
        )
        
        NavigationStack {
            GameAnalysisView(game: game, viewModel: viewModel)
        }
    }
} 