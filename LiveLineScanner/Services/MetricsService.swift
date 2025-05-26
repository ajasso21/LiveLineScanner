import Foundation

/// Service for fetching and managing game metrics
class MetricsService {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func fetchMetrics(for game: Game) async throws -> ChatGPTMetrics {
        return try await openAIService.analyzeGame(game)
    }
} 