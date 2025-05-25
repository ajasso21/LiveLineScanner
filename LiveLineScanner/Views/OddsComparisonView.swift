// OddsComparisonView.swift
import SwiftUI
import Charts
import Foundation

// MARK: - Views
struct OddsComparisonView: View {
    @EnvironmentObject private var gameBrowserVM: GameBrowserViewModel
    @StateObject private var viewModel = OddsComparisonViewModel()
    @State private var selectedSport: APISport? = nil
    @State private var showFilters = false
    @State private var selectedMarkets: Set<String> = ["h2h", "spreads", "player_points"]
    @State private var selectedBooks: Set<String> = []
    @State private var showDetail: OddsLine? = nil
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .moveMagnitude

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                OddsSportPickerView(selectedSport: $selectedSport, sports: viewModel.sports)
                searchAndSortBar
                listView
            }
            .background(Color.themeBackground)
            .navigationTitle("Odds Comparison")
            .toolbar { toolbarItems }
            .sheet(isPresented: $showFilters) { filtersSheet }
            .sheet(item: $showDetail) { line in detailSheet(line) }
            .task { 
                viewModel.apiKey = APIConfig.shared.apiKey
                await viewModel.fetchSports() 
            }
        }
    }

    private var searchAndSortBar: some View {
        HStack {
            TextField("Search markets/outcomes...", text: $searchText)
                .padding(8)
                .background(Color.themeSearchField)
                .cornerRadius(8)
                .font(.body)

            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
        }
        .padding([.horizontal, .bottom])
        .background(Color.themeCard)
    }

    private var listView: some View {
        Group {
            if let sport = selectedSport {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredAndSortedLines) { line in
                            OddsLineRow(line: line)
                                .onTapGesture { showDetail = line }
                                .background(Color.themeCard)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .background(Color.themeBackground)
                .refreshable { 
                    if selectedSport != nil {
                        await viewModel.fetchBestLines(for: selectedSport!)
                    }
                }
            } else {
                Spacer()
                Text("Select a sport to view odds")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Spacer()
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ArbitrageView()
                        .environmentObject(viewModel)
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AlertsView()
                } label: {
                    Image(systemName: "bell.badge")
                        .font(.title2)
                }
            }
        }
    }

    private var filtersSheet: some View {
        let markets = viewModel.allMarkets
        let books = viewModel.allBooks
        return FiltersView(
            markets: markets,
            books: books,
            selectedMarkets: $selectedMarkets,
            selectedBooks: $selectedBooks
        )
    }

    private func detailSheet(_ line: OddsLine) -> some View {
        BookmakerQuotesView(line: line)
    }

    // MARK: - Data Processing
    private var filteredAndSortedLines: [OddsLine] {
        let lines = viewModel.bestLines
        return lines
            .filter { selectedMarkets.contains($0.market) }
            .filter { selectedBooks.isEmpty || selectedBooks.contains($0.bestBook) }
            .filter { searchText.isEmpty ||
                $0.market.localizedCaseInsensitiveContains(searchText) ||
                $0.outcome.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { line1, line2 in
                switch sortOption {
                case .moveMagnitude:
                    return abs(line1.movement ?? 0) > abs(line2.movement ?? 0)
                case .market:
                    return line1.market < line2.market
                case .alphabetical:
                    return line1.outcome < line2.outcome
                }
            }
    }
}

// MARK: - OddsSportPickerView
struct OddsSportPickerView: View {
    @Binding var selectedSport: APISport?
    let sports: [APISport]

    var body: some View {
        Picker("Sport", selection: $selectedSport) {
            Text("Select Sport").tag(Optional<APISport>.none)
            ForEach(sports, id: \.self) { sport in
                Text(sport.title).tag(Optional<APISport>.some(sport))
            }
        }
        .pickerStyle(.menu)
        .padding()
        .background(Color.themeCard)
    }
}

struct OddsLineRow: View {
    let line: OddsLine
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(line.market.capitalized)
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                Text(line.outcome)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", line.bestPrice))
                    .font(.title3)
                    .foregroundColor(line.movementColor)
                Text(line.bestBook.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let delta = line.movement {
                    Text(String(format: "%+0.2f", delta))
                        .font(.caption2)
                        .foregroundColor(line.movementColor)
                }
            }
        }
        .padding()
    }
}

struct FiltersView: View {
    let markets: [String]
    let books: [String]
    @Binding var selectedMarkets: Set<String>
    @Binding var selectedBooks: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Markets")) {
                    ForEach(markets, id: \.self) { m in
                        Toggle(m.capitalized, isOn: Binding(
                            get: { selectedMarkets.contains(m) },
                            set: { flag in
                                if flag { selectedMarkets.insert(m) } else { selectedMarkets.remove(m) }
                            }
                        ))
                    }
                }
                Section(header: Text("Bookmakers")) {
                    ForEach(books, id: \.self) { b in
                        Toggle(b.capitalized, isOn: Binding(
                            get: { selectedBooks.contains(b) },
                            set: { flag in
                                if flag { selectedBooks.insert(b) } else { selectedBooks.remove(b) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BookmakerQuotesView: View {
    let line: OddsLine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(line.allQuotes, id: \.book) { quote in
                HStack {
                    Text(quote.book.capitalized)
                        .foregroundColor(Color.themeText)
                    Spacer()
                    Text(String(format: "%.2f", quote.price))
                        .foregroundColor(quote.price == line.bestPrice ? Color.themeUp : Color.themeText)
                }
            }
            .navigationTitle("\(line.market.capitalized) - \(line.outcome)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        OddsComparisonView()
            .environmentObject(GameBrowserViewModel())
    }
} 