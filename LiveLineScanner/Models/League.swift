
// Sport.swift → rename the file to League.swift after pasting
import Foundation

/// Represents a sports league (formerly “Sport”)
struct League: Identifiable, Codable {
    /// e.g. "basketball_nba", "baseball_mlb"
    let key: String
    /// e.g. "NBA", "MLB"
    let title: String

    var id: String { key }
}
