// PropBetView.swift
import SwiftUI
import Charts
import UniformTypeIdentifiers

// MARK: - Model
struct PlayerStat: Codable, Identifiable, Equatable {
    var id: UUID
    let name: String
    let mean: Double
    let stddev: Double
    
    init(id: UUID = UUID(), name: String, mean: Double, stddev: Double) {
        self.id = id
        self.name = name
        self.mean = mean
        self.stddev = stddev
    }
    
    static func == (lhs: PlayerStat, rhs: PlayerStat) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chart Components
struct PlayerDistributionMarks: ChartContent {
    let stat: PlayerStat
    let values: [Double]
    
    var body: some ChartContent {
        ForEach(Array(values.enumerated()), id: \.offset) { _, value in
            LineMark(
                x: .value("Points", value),
                y: .value("Frequency", 1)
            )
            .foregroundStyle(by: .value("Player", stat.name))
            .opacity(0.4)
        }
        
        RuleMark(
            x: .value("Mean", stat.mean)
        )
        .foregroundStyle(by: .value("Player", "\(stat.name) Mean"))
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        
        RectangleMark(
            xStart: .value("- σ", stat.mean - stat.stddev),
            xEnd: .value("+ σ", stat.mean + stat.stddev),
            y: .value("Range", 0)
        )
        .foregroundStyle(by: .value("Player", stat.name))
        .opacity(0.1)
    }
}

// MARK: - ViewModel
@MainActor
class PropBetViewModel: ObservableObject {
    @Published var stats: [PlayerStat] = []
    @Published var simulations: [UUID: [Double]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Update your API key here
    private let apiKey = "2574af6be81d290b18569aa5f2a45d29" // Replace with your API key from the-odds-api.com
    private let session = URLSession.shared

    /// Fetches live player-points props and converts to mean/stddev stats.
    func fetchProps() async {
        isLoading = true
        defer { isLoading = false }

        let urlString =
          "https://api.the-odds-api.com/v4/sports/basketball_nba/odds/?apiKey=\(apiKey)&regions=us&markets=player_points"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        do {
            let (data, _) = try await session.data(from: url)
            let raw = try JSONDecoder().decode([ApiResponse].self, from: data)
            guard let firstBook = raw.first?.bookmakers.first else {
                errorMessage = "No data"
                return
            }

            stats = firstBook.markets
                .first { $0.key == "player_points" }?
                .outcomes
                .map { outcome in
                    PlayerStat(
                        name: outcome.name,
                        mean: outcome.price,
                        stddev: max(0.1, outcome.price * 0.1)
                    )
                } ?? []

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Runs Monte Carlo for every stat concurrently.
    func runAllSimulations(rounds: Int = 10000) async {
        isLoading = true
        defer { isLoading = false }

        var newResults: [UUID: [Double]] = [:]

        await withTaskGroup(of: (UUID, [Double]).self) { group in
            for stat in stats {
                group.addTask {
                    var results = [Double]()
                    for _ in 0..<rounds {
                        let u1 = Double.random(in: 0...1)
                        let u2 = Double.random(in: 0...1)
                        let z0 = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
                        results.append(stat.mean + z0 * stat.stddev)
                    }
                    return (stat.id, results)
                }
            }

            for await (id, res) in group {
                newResults[id] = res
            }
        }

        simulations = newResults
    }
}

// MARK: - View
struct PropBetView: View {
    @StateObject private var vm = PropBetViewModel()
    @State private var rounds: Double = 10000

    var body: some View {
        NavigationView {
            VStack {
                statusView
                playerStatsList
                simulationControls
                distributionChart
            }
            .navigationTitle("Prop Bet Analyzer")
            .task { await vm.fetchProps() }
            .refreshable {
                await vm.fetchProps()
            }
            .animation(.easeInOut, value: vm.stats)
            .animation(.easeInOut, value: vm.isLoading)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if let err = vm.errorMessage {
            Text("⚠️ \(err)")
                .foregroundColor(.red)
                .padding()
        }
        if vm.isLoading && vm.stats.isEmpty {
            ProgressView("Loading props…")
                .padding()
        }
    }

    @ViewBuilder
    private var playerStatsList: some View {
        if !vm.stats.isEmpty {
            List(vm.stats) { stat in
                HStack {
                    Text(stat.name)
                    Spacer()
                    Text(String(format: "μ=%.2f σ=%.2f", stat.mean, stat.stddev))
                        .monospacedDigit()
                }
            }
        }
    }

    private var simulationControls: some View {
        VStack {
            HStack {
                Text("Rounds: \(Int(rounds))")
                Slider(value: $rounds, in: 1000...50000, step: 1000)
            }
            .padding()
            
            Button("Run All Simulations") {
                Task { await vm.runAllSimulations(rounds: Int(rounds)) }
            }
            .disabled(vm.isLoading || vm.stats.isEmpty)
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var distributionChart: some View {
        if !vm.simulations.isEmpty {
            Chart {
                ForEach(vm.stats) { stat in
                    if let values = vm.simulations[stat.id] {
                        PlayerDistributionMarks(stat: stat, values: values)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let points = value.as(Double.self) {
                            Text(String(format: "%.1f", points))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.2))
                }
            }
            .chartLegend(position: .top, alignment: .center)
            .chartForegroundStyleScale(range: [.blue, .green, .orange, .purple, .red])
            .frame(height: 300)
            .padding()
            .animation(.easeInOut, value: vm.simulations)
            
            // Stats summary
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(vm.stats) { stat in
                        if let values = vm.simulations[stat.id] {
                            StatsSummaryCard(stat: stat, values: values)
                        }
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.simulations)
            }
        }
    }
}

// MARK: - Stats Summary Card
struct StatsSummaryCard: View {
    let stat: PlayerStat
    let values: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.name)
                .font(.headline)
            Text("Mean: \(String(format: "%.1f", values.reduce(0, +) / Double(values.count)))")
            Text("Min: \(String(format: "%.1f", values.min() ?? 0))")
            Text("Max: \(String(format: "%.1f", values.max() ?? 0))")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.1)))
    }
}

// Support types for API decoding
private extension PropBetViewModel {
    struct ApiResponse: Codable {
        let bookmakers: [Bookmaker]
    }
    struct Bookmaker: Codable {
        let markets: [Market]
    }
    struct Market: Codable {
        let key: String
        let outcomes: [Outcome]
    }
    struct Outcome: Codable {
        let name: String
        let price: Double
    }
}

#Preview {
    PropBetView()
}