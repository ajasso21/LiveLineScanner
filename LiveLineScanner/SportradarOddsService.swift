import Foundation
import SwiftUI

enum OddsError: Error {
    case invalidAPIKey
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case invalidURL
    case forbidden
    case rateLimitExceeded
}

@MainActor
class SportradarOddsService {
    enum MarketProduct: String, CaseIterable {
        case prematch        = "oddscomparison-prematch"
        case playerProps     = "oddscomparison-player-props"
        case futures        = "oddscomparison-futures"
        case liveOdds       = "oc-live-odds"
    }
    
    private let session = URLSession.shared
    private let locale = "en"
    private let decoder: JSONDecoder
    
    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Fetches odds for all four markets in one go for a single event.
    func fetchAllMarkets(
        sport: String,       // "mlb", "nba", "nhl"
        eventId: String
    ) async throws -> (event: SportEvent?, markets: [MarketProduct: [Bookmaker]]) {
        guard APIConfig.shared.isKeyValid else {
            throw OddsError.invalidAPIKey
        }
        
        var result: [MarketProduct: [Bookmaker]] = [:]
        var eventDetails: SportEvent?
        
        for product in MarketProduct.allCases {
            let url = makeOddsURL(
                product: product,
                sport: sport,
                pathComponent: "events/\(eventId)/odds"
            )
            do {
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OddsError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    let decoded = try decoder.decode(ScheduleResponse.self, from: data)
                    eventDetails = decoded.sport_event
                    if let books = decoded.bookmakers {
                        result[product] = books
                    }
                case 401:
                    throw OddsError.unauthorized
                default:
                    throw OddsError.invalidResponse
                }
            } catch let error as OddsError {
                throw error
            } catch {
                throw OddsError.networkError(error)
            }
        }
        
        return (eventDetails, result)
    }
    
    /// Lists upcoming/prematch schedules for a sport
    func fetchSchedules(for sport: String? = nil) async throws -> [ScheduleResponse] {
        guard !APIConfig.shared.apiKey.isEmpty else {
            throw OddsError.invalidAPIKey
        }
        
        let baseURL = "https://api.sportradar.com/oddscomparison-prematch/v4/en/odds"
        let endpoint = sport.map { "\($0)/schedules" } ?? "all/schedules"
        let urlString = "\(baseURL)/\(endpoint).json?api_key=\(APIConfig.shared.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw OddsError.invalidURL
        }
        
        print("🌐 Requesting URL: \(baseURL)/\(endpoint).json")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OddsError.invalidResponse
            }
            
            print("📦 API Response: \(String(data: data, encoding: .utf8) ?? "No response data")")
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    // First try to decode as wrapped response
                    let wrapper = try JSONDecoder().decode(SportradarResponse.self, from: data)
                    return wrapper.schedules
                } catch {
                    // If that fails, try to decode as direct array
                    return try JSONDecoder().decode([ScheduleResponse].self, from: data)
                }
            case 401:
                print("⚠️ Authorization failed. API Key: \(APIConfig.shared.apiKey)")
                throw OddsError.unauthorized
            case 403:
                throw OddsError.forbidden
            case 429:
                throw OddsError.rateLimitExceeded
            default:
                throw OddsError.invalidResponse
            }
        } catch let error as OddsError {
            throw error
        } catch {
            throw OddsError.networkError(error)
        }
    }
    
    private func makeOddsURL(
        product: MarketProduct,
        sport: String,
        pathComponent: String
    ) -> URL {
        let base = "https://api.sportradar.com"
        let urlString = [
            base,
            product.rawValue + "/v4",
            locale,
            "odds",
            sport,
            pathComponent + ".json"
        ].joined(separator: "/")
        
        var comps = URLComponents(string: urlString)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: APIConfig.shared.apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        
        // Print URL for debugging (without API key)
        print("🌐 Requesting URL:", urlString)
        
        return comps.url!
    }
}