import Foundation

public class OddsService {
    private let apiKey: String
    private let baseURL = "https://api.sportradar.com"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func fetchPrematchOdds(for game: SportsGame) async throws -> [OddsData] {
        // First get the competition mapping
        let mappingURL = "\(baseURL)/oddscomparison-prematch/trial/v2/en/competitions/mappings.json"
        let mappingData = try await fetchData(from: mappingURL)
        
        // Then get the actual odds
        let oddsURL = "\(baseURL)/oddscomparison-prematch/trial/v2/en/competitions/\(game.id)/odds.json"
        let oddsData = try await fetchData(from: oddsURL)
        
        // Parse and return the odds
        return parseOddsData(oddsData)
    }
    
    public func fetchPlayerProps(for game: SportsGame) async throws -> [OddsData] {
        // First get the player mappings
        let mappingURL = "\(baseURL)/oddscomparison-player-props/trial/v2/en/players/mappings.json"
        let mappingData = try await fetchData(from: mappingURL)
        
        // Then get the props
        let propsURL = "\(baseURL)/oddscomparison-player-props/trial/v2/en/games/\(game.id)/props.json"
        let propsData = try await fetchData(from: propsURL)
        
        // Parse and return the props
        return parsePropsData(propsData)
    }
    
    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-api-key": apiKey
        ]
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    private func parseOddsData(_ data: Data) -> [OddsData] {
        // TODO: Implement JSON parsing for odds data
        // This will depend on the exact structure of the SportRadar API response
        return []
    }
    
    private func parsePropsData(_ data: Data) -> [OddsData] {
        // TODO: Implement JSON parsing for props data
        // This will depend on the exact structure of the SportRadar API response
        return []
    }
} 