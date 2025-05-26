import Foundation
import Combine
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var selectedLeague: League = .nba {
        didSet {
            Task {
                await loadSchedule()
            }
        }
    }
    @Published var selectedDay: DayOption = .today {
        didSet {
            filterGames()
        }
    }
    @Published var games: [Game] = []
    @Published var filteredGames: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let sportradarService = SportradarService()
    
    func loadSchedule() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📊 Loading schedule for \(selectedLeague)")
            games = try await sportradarService.fetchSchedule(league: selectedLeague)
            filterGames()
        } catch {
            print("❌ Error loading schedule: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func filterGames() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        filteredGames = games.filter { game in
            let gameDate = calendar.startOfDay(for: game.startTime)
            switch selectedDay {
            case .today:
                return calendar.isDate(gameDate, inSameDayAs: today)
            case .tomorrow:
                return calendar.isDate(gameDate, inSameDayAs: tomorrow)
            }
        }.sorted { $0.startTime < $1.startTime }
    }
}

// MARK: - Array Extension
extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
} 