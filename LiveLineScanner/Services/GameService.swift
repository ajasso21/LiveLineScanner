import Foundation

class GameService {
    private let apiKey: String
    private let baseURL = "https://api.sportradar.com"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchGames(for league: SportsLeague, date: Date) async throws -> [SportsGame] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/\(league.rawValue)/trial/v8/en/games/\(dateString)/schedule.json?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the response based on the league
        switch league {
        case .nba:
            return try parseNBAGames(data)
        case .mlb:
            return try parseMLBGames(data)
        case .nhl:
            return try parseNHLGames(data)
        }
    }
    
    private func parseNBAGames(_ data: Data) throws -> [SportsGame] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(NBAScheduleResponse.self, from: data)
        
        return response.games.map { game in
            SportsGame(
                id: game.id,
                home: SportsTeam(
                    id: game.home.id,
                    name: game.home.name,
                    abbreviation: game.home.alias
                ),
                away: SportsTeam(
                    id: game.away.id,
                    name: game.away.name,
                    abbreviation: game.away.alias
                ),
                scheduled: ISO8601DateFormatter().date(from: game.scheduled) ?? Date(),
                status: GameStatus(rawValue: game.status) ?? .scheduled,
                league: .nba
            )
        }
    }
    
    private func parseMLBGames(_ data: Data) throws -> [SportsGame] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(MLBScheduleResponse.self, from: data)
        
        return response.games.map { game in
            SportsGame(
                id: game.id,
                home: SportsTeam(
                    id: game.home.id,
                    name: game.home.name,
                    abbreviation: game.home.abbr
                ),
                away: SportsTeam(
                    id: game.away.id,
                    name: game.away.name,
                    abbreviation: game.away.abbr
                ),
                scheduled: ISO8601DateFormatter().date(from: game.scheduled) ?? Date(),
                status: GameStatus(rawValue: game.status) ?? .scheduled,
                league: .mlb
            )
        }
    }
    
    private func parseNHLGames(_ data: Data) throws -> [SportsGame] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(NHLScheduleResponse.self, from: data)
        
        return response.games.map { game in
            SportsGame(
                id: game.id,
                home: SportsTeam(
                    id: game.home.id,
                    name: game.home.name,
                    abbreviation: game.home.alias
                ),
                away: SportsTeam(
                    id: game.away.id,
                    name: game.away.name,
                    abbreviation: game.away.alias
                ),
                scheduled: ISO8601DateFormatter().date(from: game.scheduled) ?? Date(),
                status: GameStatus(rawValue: game.status) ?? .scheduled,
                league: .nhl
            )
        }
    }
}

// Response models
struct NBAScheduleResponse: Codable {
    let games: [NBAGame]
}

struct NBAGame: Codable {
    let id: String
    let status: String
    let scheduled: String
    let home: NBATeam
    let away: NBATeam
}

struct NBATeam: Codable {
    let id: String
    let name: String
    let alias: String
}

struct MLBScheduleResponse: Codable {
    let games: [MLBGame]
}

struct MLBGame: Codable {
    let id: String
    let status: String
    let scheduled: String
    let home: MLBTeam
    let away: MLBTeam
}

struct MLBTeam: Codable {
    let id: String
    let name: String
    let abbr: String
}

struct NHLScheduleResponse: Codable {
    let games: [NHLGame]
}

struct NHLGame: Codable {
    let id: String
    let status: String
    let scheduled: String
    let home: NHLTeam
    let away: NHLTeam
}

struct NHLTeam: Codable {
    let id: String
    let name: String
    let alias: String
} 