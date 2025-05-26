import Foundation

/// Service for interacting with OpenAI's API
public class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func analyzeGame(_ game: SportsGame) async throws -> ChatGPTMetrics {
        // TODO: Implement OpenAI API call
        return ChatGPTMetrics(
            trueProb: 0.5,
            weatherImpact: nil,
            trends: "No trends available"
        )
    }
    
    public func analyzeBettingOpportunities(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a sports betting analyst. Analyze the provided data and return a JSON array of betting opportunities with true probabilities, expected values, and Kelly criterion recommendations."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the OpenAI response
        let decoder = JSONDecoder()
        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
        
        return openAIResponse.choices.first?.message.content ?? ""
    }
}

// OpenAI API response structures
private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 