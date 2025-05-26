// SportradarService.swift
import Foundation

enum SportradarError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case noGamesFound
}

/// Fetches schedules from Sportradar
@MainActor
public class SportradarService {
    private let session: URLSession
    private let apiKey = "U1TpntzxSZ31ttrm2o6O190nIddDSnkDbboHsbfN"
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// Fetches the schedule for a given league and date.
    /// - Parameters:
    ///   - league: .nba, .mlb, .nhl, or .nfl
    ///   - date: the calendar date to fetch
    /// - Returns: An array of `Game` imported from APIConfig.swift
    public func fetchSchedule(league: League) async throws -> [Game] {
        print("🏀 Starting schedule fetch for \(league)")
        let sport = sportType(for: league)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        // Get today's and tomorrow's dates
        let calendar = Calendar.current
        let currentDate = Date()
        let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        
        let currentDateString = dateFormatter.string(from: currentDate)
        let nextDateString = dateFormatter.string(from: nextDate)
        
        print("📅 Fetching \(league) schedule for dates: \(currentDateString) and \(nextDateString)")
        
        // Fetch both today's and tomorrow's schedules
        async let currentGames = fetchGamesForDate(sport: sport, dateString: currentDateString, league: league)
        async let nextGames = fetchGamesForDate(sport: sport, dateString: nextDateString, league: league)
        
        // Combine results
        let (current, next) = try await (currentGames, nextGames)
        let allGames = current + next
        print("✅ Total \(league) games fetched: \(allGames.count)")
        return allGames
    }
    
    private func fetchGamesForDate(sport: String, dateString: String, league: League) async throws -> [Game] {
        // Use v7 for NHL, v8 for other sports
        let version = league == .nhl ? "v7" : "v8"
        let urlString = "https://api.sportradar.com/\(sport)/trial/\(version)/en/games/\(dateString)/schedule.json"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL constructed")
            throw SportradarError.invalidURL
        }
        
        print("🌐 Fetching \(league) schedule from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-api-key": apiKey
        ]
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw SportradarError.invalidResponse
            }
            
            print("📡 \(league) Response status code: \(httpResponse.statusCode)")
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 \(league) Raw response: \(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let games = try decodeSchedule(data: data, league: league)
                print("✅ Successfully decoded \(games.count) \(league) games for \(dateString)")
                return games
            default:
                print("❌ Unexpected status code for \(league): \(httpResponse.statusCode)")
                throw SportradarError.invalidResponse
            }
        } catch let error as SportradarError {
            print("❌ \(league) Sportradar error: \(error)")
            throw error
        } catch {
            print("❌ \(league) Network error: \(error.localizedDescription)")
            throw SportradarError.networkError(error)
        }
    }
    
    private func decodeSchedule(data: Data, league: League) throws -> [Game] {
        switch league {
        case .nba:
            return try decodeNBASchedule(data: data)
        case .mlb:
            return try decodeMLBSchedule(data: data)
        case .nhl:
            return try decodeNHLSchedule(data: data)
        case .nfl:
            // TODO: Implement NFL
            return []
        }
    }
    
    private func decodeNBASchedule(data: Data) throws -> [Game] {
        struct SportradarResponse: Codable {
            let date: String
            let league: LeagueInfo
            let games: [SportradarGame]
            
            struct LeagueInfo: Codable {
                let id: String
                let name: String
                let alias: String
            }
        }
        
        struct SportradarGame: Codable {
            let id: String
            let status: String
            let title: String
            let scheduled: String
            let home: Team
            let away: Team
            
            struct Team: Codable {
                let name: String
                let alias: String
                let id: String
                let seed: Int?
            }
        }
        
        do {
            let response = try JSONDecoder().decode(SportradarResponse.self, from: data)
            let dateFormatter = ISO8601DateFormatter()
            
            return response.games.compactMap { game -> Game? in
                guard let date = dateFormatter.date(from: game.scheduled) else { return nil }
                
                return Game(
                    id: game.id,
                    home: game.home.name,
                    away: game.away.name,
                    startTime: date
                )
            }
        } catch {
            print("❌ NBA Decoding error: \(error)")
            throw SportradarError.decodingError
        }
    }
    
    private func decodeMLBSchedule(data: Data) throws -> [Game] {
        print("⚾ Starting MLB schedule decoding")
        struct SportradarResponse: Codable {
            let league: LeagueInfo
            let date: String
            let games: [SportradarGame]
            
            struct LeagueInfo: Codable {
                let id: String
                let name: String
                let alias: String
            }
        }
        
        struct SportradarGame: Codable {
            let id: String
            let status: String
            let scheduled: String
            let home: Team
            let away: Team
            
            struct Team: Codable {
                let name: String
                let market: String?
                let abbr: String
            }
        }
        
        do {
            print("⚾ Attempting to decode MLB response")
            let response = try JSONDecoder().decode(SportradarResponse.self, from: data)
            let dateFormatter = ISO8601DateFormatter()
            
            let games = response.games.compactMap { game -> Game? in
                guard let date = dateFormatter.date(from: game.scheduled) else {
                    print("❌ Failed to parse date for MLB game: \(game.scheduled)")
                    return nil
                }
                
                let homeTeam = game.home.market != nil ? "\(game.home.market!) \(game.home.name)" : game.home.name
                let awayTeam = game.away.market != nil ? "\(game.away.market!) \(game.away.name)" : game.away.name
                
                return Game(
                    id: game.id,
                    home: homeTeam,
                    away: awayTeam,
                    startTime: date
                )
            }
            
            print("✅ Successfully decoded \(games.count) MLB games")
            return games
        } catch {
            print("❌ MLB Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: expected \(type) - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error: \(decodingError)")
                }
            }
            throw SportradarError.decodingError
        }
    }
    
    private func decodeNHLSchedule(data: Data) throws -> [Game] {
        print("🏒 Starting NHL schedule decoding")
        struct SportradarResponse: Codable {
            let league: LeagueInfo
            let date: String
            let games: [SportradarGame]
            
            struct LeagueInfo: Codable {
                let id: String
                let name: String
                let alias: String
            }
        }
        
        struct SportradarGame: Codable {
            let id: String
            let status: String
            let scheduled: String
            let home: Team
            let away: Team
            
            struct Team: Codable {
                let name: String
                let market: String?
                let alias: String
            }
        }
        
        do {
            print("🏒 Attempting to decode NHL response")
            let response = try JSONDecoder().decode(SportradarResponse.self, from: data)
            let dateFormatter = ISO8601DateFormatter()
            
            let games = response.games.compactMap { game -> Game? in
                guard let date = dateFormatter.date(from: game.scheduled) else {
                    print("❌ Failed to parse date for NHL game: \(game.scheduled)")
                    return nil
                }
                
                let homeTeam = game.home.market != nil ? "\(game.home.market!) \(game.home.name)" : game.home.name
                let awayTeam = game.away.market != nil ? "\(game.away.market!) \(game.away.name)" : game.away.name
                
                return Game(
                    id: game.id,
                    home: homeTeam,
                    away: awayTeam,
                    startTime: date
                )
            }
            
            print("✅ Successfully decoded \(games.count) NHL games")
            return games
        } catch {
            print("❌ NHL Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: expected \(type) - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error: \(decodingError)")
                }
            }
            throw SportradarError.decodingError
        }
    }
    
    private func sportType(for league: League) -> String {
        switch league {
        case .nba: return "nba"
        case .mlb: return "mlb"
        case .nhl: return "nhl"
        case .nfl: return "nfl"
        }
    }
}
