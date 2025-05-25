import SwiftUI
import Combine
import UserNotifications
import Charts

// MARK: - ViewModel
@MainActor
class LiveVisualizationViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var selectedGame: Game? = nil
    @Published var liveScores: [LiveScore] = []
    @Published var oddsHistory: [OddsPoint] = []
    @Published var heatmapData: [String: Int] = [:] // watchlist team -> hotness count

    private var cancellables = Set<AnyCancellable>()
    private let pollingInterval: TimeInterval = 30
    private var timerCancellable: AnyCancellable?
    private let alertsVM = AlertsViewModel.shared
    
    // Constants for alert thresholds
    private let significantOddsChange: Double = 0.15 // 15% change
    private let significantScoreChange: Int = 5 // 5 point run
    private var lastOddsPrice: Double?
    private var lastScore: LiveScore?

    init() {
        fetchGames()
    }

    func fetchGames() {
        // Fetch today's games for MLB, NBA, NHL
        // For brevity, assume local JSON or a combined API
        // Here, sample data:
        games = [
            Game(id: "game1", homeTeam: "Lakers", awayTeam: "Heat", startTime: Date()),
            Game(id: "game2", homeTeam: "Yankees", awayTeam: "Red Sox", startTime: Date())
        ]
    }

    func select(game: Game) {
        selectedGame = game
        liveScores.removeAll()
        oddsHistory.removeAll()
        lastOddsPrice = nil
        lastScore = nil
        startPolling()
    }

    private func startPolling() {
        timerCancellable = Timer.publish(every: pollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchLiveData()
                }
            }
    }

    func fetchLiveData() async {
        guard let game = selectedGame else { return }
        
        // 1. Fetch live score
        // Replace with real API call
        let newScore = LiveScore(homeScore: Int.random(in: 80...100), awayScore: Int.random(in: 75...100), timestamp: Date())
        liveScores.append(newScore)
        
        // Check for significant score changes
        if let lastScore = lastScore {
            let homeRun = newScore.homeScore - lastScore.homeScore
            let awayRun = newScore.awayScore - lastScore.awayScore
            
            if abs(homeRun) >= significantScoreChange {
                let team = homeRun > 0 ? game.homeTeam : game.awayTeam
                notifyScoreRun(points: abs(homeRun), team: team)
            }
            if abs(awayRun) >= significantScoreChange {
                let team = awayRun > 0 ? game.awayTeam : game.homeTeam
                notifyScoreRun(points: abs(awayRun), team: team)
            }
        }
        lastScore = newScore

        // 2. Fetch current odds
        // Replace with real API call
        let latestPrice = Double.random(in: 1.5...3.0)
        oddsHistory.append(OddsPoint(timestamp: Date(), price: latestPrice))
        
        // Check for significant odds movement
        if let lastPrice = lastOddsPrice {
            let pctChange = (latestPrice - lastPrice) / lastPrice
            if abs(pctChange) >= significantOddsChange {
                notifyOddsMovement(
                    oldPrice: lastPrice,
                    newPrice: latestPrice,
                    game: game
                )
            }
        }
        lastOddsPrice = latestPrice

        // 3. Update heatmap: increment count
        heatmapData[game.homeTeam, default: 0] += 1
        heatmapData[game.awayTeam, default: 0] += 1
    }
    
    private func notifyScoreRun(points: Int, team: String) {
        guard let game = selectedGame else { return }
        let content = UNMutableNotificationContent()
        content.title = "Score Alert"
        content.body = "\(team) on a \(points)-point run! (\(game.awayTeam) @ \(game.homeTeam))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "score_run_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyOddsMovement(oldPrice: Double, newPrice: Double, game: Game) {
        let pctChange = ((newPrice - oldPrice) / oldPrice) * 100
        let direction = newPrice > oldPrice ? "up" : "down"
        
        // Check value index alert
        alertsVM.checkAndFireAlerts(valueIndex: abs(pctChange / 100))
        
        // Create immediate notification
        let content = UNMutableNotificationContent()
        content.title = "Odds Movement"
        content.body = String(format: "Odds moved %.1f%% %@ for %@ @ %@", 
                            abs(pctChange), direction, game.awayTeam, game.homeTeam)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "odds_move_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }

    func stop() {
        timerCancellable?.cancel()
    }
}

struct LiveVisualizationView: View {
    @StateObject private var viewModel = LiveVisualizationViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Game Selection
                    if let selectedGame = viewModel.selectedGame {
                        gameDetailsSection(for: selectedGame)
                    } else {
                        gameSelectionSection
                    }
                    
                    if viewModel.selectedGame != nil {
                        // Live Score
                        if !viewModel.liveScores.isEmpty {
                            scoreSection
                        }
                        
                        // Odds Movement
                        if !viewModel.oddsHistory.isEmpty {
                            oddsSection
                        }
                        
                        // Heatmap
                        if !viewModel.heatmapData.isEmpty {
                            heatmapSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Live Visualization")
            .onDisappear {
                viewModel.stop()
            }
        }
    }
    
    private var gameSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select a Game")
                .font(.title2)
                .bold()
            
            if viewModel.games.isEmpty {
                EmptyStateView(
                    title: "No Games Available",
                    message: "Check back later for live games",
                    systemImage: "sportscourt"
                )
            } else {
                ForEach(viewModel.games) { game in
                    Button {
                        viewModel.select(game: game)
                    } label: {
                        GameRowView(game: game)
                    }
                }
            }
        }
    }
    
    private func gameDetailsSection(for game: Game) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(game.awayTeam) @ \(game.homeTeam)")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Change") {
                    viewModel.selectedGame = nil
                }
            }
            
            Text(game.startTime.formatted(.dateTime))
                .foregroundColor(.secondary)
        }
    }
    
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Score")
                .font(.title2)
                .bold()
            
            if let lastScore = viewModel.liveScores.last {
                HStack {
                    Text("\(lastScore.awayScore)")
                        .font(.largeTitle)
                    Text("-")
                        .font(.title)
                    Text("\(lastScore.homeScore)")
                        .font(.largeTitle)
                }
                .frame(maxWidth: .infinity)
                
                // Score Chart
                Chart(viewModel.liveScores, id: \.timestamp) { score in
                    LineMark(
                        x: .value("Time", score.timestamp),
                        y: .value("Home", score.homeScore),
                        series: .value("Team", "Home")
                    )
                    .foregroundStyle(.blue)
                    
                    LineMark(
                        x: .value("Time", score.timestamp),
                        y: .value("Away", score.awayScore),
                        series: .value("Team", "Away")
                    )
                    .foregroundStyle(.red)
                }
                .frame(height: 200)
            }
        }
    }
    
    private var oddsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Odds Movement")
                .font(.title2)
                .bold()
            
            Chart(viewModel.oddsHistory, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
        }
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity Heatmap")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(Array(viewModel.heatmapData.keys.sorted()), id: \.self) { team in
                    let intensity = viewModel.heatmapData[team] ?? 0
                    VStack {
                        Text(team)
                            .font(.caption)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(Double(intensity) / 10.0))
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

struct GameRowView: View {
    let game: Game
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(game.awayTeam) @ \(game.homeTeam)")
                    .font(.headline)
                Text(game.startTime.formatted(.dateTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    LiveVisualizationView()
} 