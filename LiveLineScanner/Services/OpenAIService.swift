import Foundation

/// Service for interacting with OpenAI's API
public class OpenAIService {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func analyzeGame(_ game: Game) async throws -> ChatGPTMetrics {
        // TODO: Implement OpenAI API call
        return ChatGPTMetrics(
            trueProb: 0.5,
            weatherImpact: nil,
            trends: "No trends available"
        )
    }
} 