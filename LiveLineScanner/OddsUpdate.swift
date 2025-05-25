// OddsUpdate.swift
import Foundation

/// Models namespace to avoid type conflicts
enum Models {}

extension Models {
    /// Represents a significant change in odds for a specific market and runner
    struct OddsUpdate: Identifiable, Hashable {
        /// Unique identifier for this update (eventId_market_runner)
        let id: String
        
        /// The event this update is for
        let eventId: String
        
        /// The market type (e.g. "h2h", "spreads")
        let market: String
        
        /// The selection/team name
        let runner: String
        
        /// Previous odds
        let oldPrice: Double
        
        /// New odds
        let newPrice: Double
        
        /// Percentage change in price (positive = increase)
        let pctChange: Double
        
        /// When this update was detected
        let timestamp: Date
        
        // Hashable conformance
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Models.OddsUpdate, rhs: Models.OddsUpdate) -> Bool {
            lhs.id == rhs.id
        }
    }
}
