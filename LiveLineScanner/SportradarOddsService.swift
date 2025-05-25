import Foundation
import SwiftUI

enum OddsError: Error {
    case invalidAPIKey
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
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
    func fetchSchedules(
        product: MarketProduct,
        sport: String
    ) async throws -> [ScheduleResponse] {
        guard !APIConfig.shared.apiKey.isEmpty else {
            throw OddsError.invalidAPIKey
        }
        
        let path = (product == .futures) ? "tournaments" : "schedules"
        let url = makeOddsURL(product: product, sport: sport, pathComponent: path)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OddsError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    return try decoder.decode([ScheduleResponse].self, from: data)
                } catch {
                    print("⚠️ Decoding error:", error)
                    throw OddsError.decodingError(error)
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
        comps.queryItems = [ URLQueryItem(name: "api_key", value: APIConfig.shared.apiKey) ]
        return comps.url!
    }
}