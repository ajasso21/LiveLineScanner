import SwiftUI

struct GameSelectionView: View {
    @StateObject private var viewModel: BettingAnalysisViewModel
    @State private var selectedLeague: SportsLeague = .nba
    @State private var games: [SportsGame] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedGameId: String?
    @State private var showAnalysis = false
    
    private let gameService: GameService
    
    init(viewModel: BettingAnalysisViewModel, gameService: GameService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.gameService = gameService
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // League selector
                Picker("League", selection: $selectedLeague) {
                    Text("NBA").tag(SportsLeague.nba)
                    Text("MLB").tag(SportsLeague.mlb)
                    Text("NHL").tag(SportsLeague.nhl)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedLeague) { _ in
                    Task {
                        await loadGames()
                    }
                }
                
                if isLoading {
                    ProgressView("Loading games...")
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(games) { game in
                                Button(action: {
                                    print("Tapped game: \(game.id)")
                                    selectedGameId = game.id
                                    showAnalysis = true
                                }) {
                                    HStack {
                                        Text("\(game.away.name) @ \(game.home.name)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Game")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadGames()
            }
            .sheet(isPresented: $showAnalysis) {
                if let selectedGame = games.first(where: { $0.id == selectedGameId }) {
                    NavigationStack {
                        GameAnalysisView(game: selectedGame, viewModel: viewModel)
                            .navigationBarItems(trailing: Button("Done") {
                                showAnalysis = false
                            })
                    }
                }
            }
        }
    }
    
    private func loadGames() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            
            let todayGames = try await gameService.fetchGames(for: selectedLeague, date: today)
            let tomorrowGames = try await gameService.fetchGames(for: selectedLeague, date: tomorrow)
            
            games = todayGames + tomorrowGames
            print("Loaded \(games.count) games")
            games.forEach { game in
                print("Game ID: \(game.id), Teams: \(game.away.name) @ \(game.home.name)")
            }
            error = nil
        } catch {
            print("Error loading games: \(error)")
            self.error = error
            games = []
        }
    }
}

// Preview provider
struct GameSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let oddsService = OddsService(apiKey: "your-api-key")
        let openAIService = OpenAIService(apiKey: "your-api-key")
        let analysisService = BettingAnalysisService(openAIService: openAIService)
        let viewModel = BettingAnalysisViewModel(oddsService: oddsService, analysisService: analysisService)
        let gameService = GameService(apiKey: "your-api-key")
        
        GameSelectionView(viewModel: viewModel, gameService: gameService)
    }
} 
