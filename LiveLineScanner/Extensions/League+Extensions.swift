
// League+Extensions.swift  (rename the file after pasting)
import Foundation

extension League {
    /// Returns a human-readable name for a league key
    func displayName() -> String {
        switch key {
        case "basketball_nba": return "NBA"
        case "baseball_mlb": return "MLB"
        case "icehockey_nhl": return "NHL"
        default: return title
        }
    }
    
    // Add any other league-specific helpers here
}
