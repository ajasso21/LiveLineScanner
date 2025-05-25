import SwiftUI

// MARK: - Models
struct MarketOutcome: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let price: Double
    
    static func == (lhs: MarketOutcome, rhs: MarketOutcome) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DisplayMarket: Identifiable {
    let id = UUID()
    let name: String
    let outcomes: [MarketOutcome]
}

// MARK: - Supporting Views
struct MarketView: View {
    let market: DisplayMarket
    
    var body: some View {
        Section(market.name) {
            ForEach(market.outcomes) { outcome in
                HStack {
                    Text(outcome.name)
                    Spacer()
                    Text(String(format: "%.2f", outcome.price))
                        .fontWeight(.bold)
                }
            }
        }
    }
}

struct OddsLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("Loading odds...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.red)
    }
}

// MARK: - Main View
struct OddsDetailView: View {
    let event: Event
    @ObservedObject var viewModel: GameBrowserViewModel
    @State private var markets: [DisplayMarket] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        List {
            if isLoading {
                OddsLoadingView()
            } else if let error = error {
                ErrorView(message: error)
            } else if markets.isEmpty {
                Text("No odds available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(markets) { market in
                    MarketView(market: market)
                }
            }
        }
        .navigationTitle("Odds")
        .task {
            await fetchOdds()
        }
    }
    
    private func fetchOdds() async {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "https://api.the-odds-api.com/v4/sports/\(event.sportKey)/events/\(event.id)/odds?apiKey=\(APIConfig.shared.apiKey)&regions=us")!
        
        do {
            let (data, _) = try await viewModel.session.data(from: url)
            let eventOdds = try JSONDecoder().decode(EventOdds.self, from: data)
            
            // Process first bookmaker's markets
            if let firstBookmaker = eventOdds.bookmakers.first {
                markets = firstBookmaker.markets.map { market in
                    DisplayMarket(
                        name: market.key,
                        outcomes: market.outcomes.map { outcome in
                            MarketOutcome(name: outcome.name, price: outcome.price)
                        }
                    )
                }
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
            print("⚠️ fetchOdds:", error)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        OddsDetailView(
            event: Event(
                id: "test",
                homeTeam: "Home",
                awayTeam: "Away",
                commenceTime: Date(),
                sportKey: "basketball_nba",
                completed: false,
                scores: nil,
                lastUpdate: nil
            ),
            viewModel: GameBrowserViewModel()
        )
    }
}

// MARK: - API Models
extension OddsDetailView {
    struct EventOdds: Codable {
        let bookmakers: [Bookmaker]
    }
    
    struct Bookmaker: Codable {
        let markets: [ApiMarket]
    }
    
    struct ApiMarket: Codable {
        let key: String
        let outcomes: [Outcome]
    }
    
    struct Outcome: Codable {
        let name: String
        let price: Double
    }
}

//
//  OddsDetailView.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/23/25.
//

