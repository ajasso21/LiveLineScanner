import Foundation

public enum SportType: String, CaseIterable {
    case nba = "NBA"
    case mlb = "MLB"
    case nhl = "NHL"
    case nfl = "NFL"
    
    var apiPath: String {
        switch self {
        case .nba: return "nba"
        case .mlb: return "mlb"
        case .nhl: return "nhl"
        case .nfl: return "nfl"
        }
    }
    
    var displayName: String {
        switch self {
        case .nba: return "NBA"
        case .mlb: return "MLB"
        case .nhl: return "NHL"
        case .nfl: return "NFL"
        }
    }
} 