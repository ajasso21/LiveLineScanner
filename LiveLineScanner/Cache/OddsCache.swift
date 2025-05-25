// OddsCache.swift
import Foundation

actor OddsCache {
    static let shared = OddsCache()
    
    // Cache expiration times
    private let sportsCacheTime: TimeInterval = 3600 // 1 hour
    private let eventsCacheTime: TimeInterval = 300  // 5 minutes
    
    // Cache structures
    private struct CacheEntry<T> {
        let timestamp: Date
        let data: T
    }
    
    private var sportsCache: CacheEntry<[SportType]>?
    private var eventsCache: [String: CacheEntry<[ScheduleResponse]>] = [:]
    
    private init() {}
    
    // MARK: - Sports Cache
    
    func cacheSports(_ sports: [SportType]) {
        sportsCache = CacheEntry(timestamp: Date(), data: sports)
    }
    
    func getCachedSports() -> [SportType]? {
        guard let cache = sportsCache,
              Date().timeIntervalSince(cache.timestamp) < sportsCacheTime
        else {
            return nil
        }
        return cache.data
    }
    
    // MARK: - Events Cache
    
    func cacheEvents(_ events: [ScheduleResponse], forSport sportKey: String) {
        eventsCache[sportKey] = CacheEntry(timestamp: Date(), data: events)
    }
    
    func getCachedEvents(forSport sportKey: String) -> [ScheduleResponse]? {
        guard let cache = eventsCache[sportKey],
              Date().timeIntervalSince(cache.timestamp) < eventsCacheTime
        else {
            return nil
        }
        return cache.data
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        sportsCache = nil
        eventsCache.removeAll()
    }
    
    func clearCache(forSport sportKey: String) {
        eventsCache.removeAll()
    }
    
    /// Returns true if we should wait before making another API call
    func shouldThrottle(forSport sportKey: String) -> Bool {
        // Ensure at least 1 second between API calls to the same sport
        guard let lastCall = eventsCache[sportKey]?.timestamp else {
            return false
        }
        return Date().timeIntervalSince(lastCall) < 1.0
    }
} 