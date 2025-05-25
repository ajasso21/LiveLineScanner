// OddsViewModel.swift
import SwiftUI
import Foundation

@MainActor
class OddsComparisonViewModel: ObservableObject {
    @Published var sports: [APISport] = []
    @Published var bestLines: [OddsLine] = []
    @Published var allMarkets: [String] = []
    @Published var allBooks: [String] = []

    var apiKey = ""
    var session = URLSession.shared
    private var history: [String: Double] = [:]

    func fetchSports() async {
        let url = URL(string: "https://api.the-odds-api.com/v4/sports/?apiKey=\(apiKey)")!
        do {
            let (data, _) = try await session.data(from: url)
            sports = try JSONDecoder().decode([APISport].self, from: data)
        } catch { print(error) }
    }

    func fetchBestLines(for sport: APISport) async {
        let urlString =
        "https://api.the-odds-api.com/v4/sports/\(sport.key)/odds/?apiKey=\(apiKey)&regions=us&markets=h2h,spreads,player_points"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await session.data(from: url)
            let eventsOdds = try JSONDecoder().decode([EventOdds].self, from: data)
            process(eventsOdds)
        } catch { print(error) }
    }

    private func process(_ eventsOdds: [EventOdds]) {
        var lines: [String: OddsLine] = [:]
        var marketsSet = Set<String>()
        var booksSet = Set<String>()

        for event in eventsOdds {
            for book in event.bookmakers {
                booksSet.insert(book.key)
                for market in book.markets {
                    marketsSet.insert(market.key)
                    for outcome in market.outcomes {
                        let key = "\(market.key)_\(outcome.name)"
                        let prev = history[key]
                        if var existing = lines[key] {
                            existing.allQuotes.append(Quote(book: book.key, price: outcome.price))
                            if outcome.price > existing.bestPrice {
                                history[key] = outcome.price
                                existing.bestPrice = outcome.price
                                existing.bestBook = book.key
                                existing.previousPrice = prev
                            }
                            lines[key] = existing
                        } else {
                            history[key] = outcome.price
                            lines[key] = OddsLine(
                                market: market.key,
                                outcome: outcome.name,
                                bestPrice: outcome.price,
                                bestBook: book.key,
                                previousPrice: prev,
                                allQuotes: [Quote(book: book.key, price: outcome.price)]
                            )
                        }
                    }
                }
            }
        }
        allMarkets = Array(marketsSet).sorted()
        allBooks = Array(booksSet).sorted()
        bestLines = lines.values.sorted { $0.market < $1.market }
    }
} 