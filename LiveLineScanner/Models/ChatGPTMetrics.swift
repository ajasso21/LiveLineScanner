import Foundation

/// Metrics provided by ChatGPT analysis
public struct ChatGPTMetrics {
    public let trueProb: Double
    public let weatherImpact: String?
    public let trends: String
    
    public init(trueProb: Double, weatherImpact: String? = nil, trends: String) {
        self.trueProb = trueProb
        self.weatherImpact = weatherImpact
        self.trends = trends
    }
} 