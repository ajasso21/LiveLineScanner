import SwiftUI

// MARK: - Supporting Views
struct FavoritesSectionView: View {
    let sports: [Sport]
    let favorites: Set<String>
    let expandedEvents: Set<String>
    let sortedEventsForSport: (String) -> [Event]
    let onEventTap: (Event) -> Void
    let onSportTap: (Sport) -> Void
    
    var body: some View {
        Section("Favorites") {
            ForEach(sports.filter { favorites.contains($0.key) }) { sport in
                SportRow(
                    sport: sport,
                    events: sortedEventsForSport(sport.key),
                    isExpanded: expandedEvents.contains(sport.key),
                    isFavorite: true,
                    onEventTap: onEventTap
                )
                .sportRowStyle(isExpanded: expandedEvents.contains(sport.key))
                .onTapGesture { onSportTap(sport) }
            }
        }
    }
}

struct AllSportsSection: View {
    let sports: [Sport]
    let favorites: Set<String>
    let expandedEvents: Set<String>
    let sortedEventsForSport: (String) -> [Event]
    let onEventTap: (Event) -> Void
    let onSportTap: (Sport) -> Void
    let onFavorite: (Sport) -> Void
    
    var body: some View {
        Section(favorites.isEmpty ? "" : "All Sports") {
            ForEach(sports) { sport in
                if !favorites.contains(sport.key) {
                    SportRow(
                        sport: sport,
                        events: sortedEventsForSport(sport.key),
                        isExpanded: expandedEvents.contains(sport.key),
                        isFavorite: false,
                        onEventTap: onEventTap
                    )
                    .sportRowStyle(isExpanded: expandedEvents.contains(sport.key))
                    .onTapGesture { onSportTap(sport) }
                    .swipeActions(edge: .leading) {
                        Button {
                            onFavorite(sport)
                        } label: {
                            Label("Favorite", systemImage: "star.fill")
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
    }
}

// MARK: - Main View
struct GameBrowserView: View {
    @StateObject private var vm = GameBrowserViewModel()
    @StateObject private var refreshManager = BackgroundRefreshManager.shared
    @State private var expandedEvents: Set<String> = []
    @State private var searchText = ""
    @State private var favorites: Set<String> = [] {
        didSet {
            withAnimation(.spring(response: 0.3)) {
                // This triggers a view update with animation when favorites changes
            }
        }
    }
    @State private var selectedEvent: Event?
    @State private var showingEventDetails = false
    @State private var showingSortOptions = false
    
    var filteredSports: [Sport] {
        if searchText.isEmpty {
            return vm.sports
        }
        return vm.sports.filter { sport in
            sport.title.localizedCaseInsensitiveContains(searchText) ||
            vm.events[sport.key]?.contains { event in
                event.homeTeam.localizedCaseInsensitiveContains(searchText) ||
                event.awayTeam.localizedCaseInsensitiveContains(searchText)
            } ?? false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RefreshStatusView(refreshManager: refreshManager)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                
                List {
                    if vm.sports.isEmpty && !vm.isLoading {
                        Text("No sports available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        if !favorites.isEmpty {
                            FavoritesSectionView(
                                sports: vm.sports,
                                favorites: favorites,
                                expandedEvents: expandedEvents,
                                sortedEventsForSport: vm.sortedEvents,
                                onEventTap: { event in
                                    selectedEvent = event
                                    showingEventDetails = true
                                },
                                onSportTap: toggleSport
                            )
                        }
                        
                        AllSportsSection(
                            sports: filteredSports,
                            favorites: favorites,
                            expandedEvents: expandedEvents,
                            sortedEventsForSport: vm.sortedEvents,
                            onEventTap: { event in
                                selectedEvent = event
                                showingEventDetails = true
                            },
                            onSportTap: toggleSport,
                            onFavorite: { sport in
                                favorites.insert(sport.key)
                            }
                        )
                    }
                }
                .searchable(text: $searchText, prompt: "Search sports or teams")
            }
            .navigationTitle("Available Games")
            .toolbar(content: toolbarContent)
            .confirmationDialog("Sort Events", isPresented: $showingSortOptions) {
                ForEach(EventSortOption.allCases, id: \.rawValue) { option in
                    Button(option.rawValue) {
                        withAnimation {
                            vm.sortOption = option
                        }
                    }
                }
            }
            .overlay {
                if vm.isLoading {
                    LoadingView()
                }
            }
            .sheet(isPresented: $showingEventDetails) {
                if let event = selectedEvent {
                    EventDetailsView(event: event)
                }
            }
            .task {
                do {
                    try await vm.fetchSports()
                } catch {
                    // Error is already handled in the view model
                    print("⚠️ Initial fetch failed:", error)
                }
            }
            .refreshable {
                do {
                    try await vm.fetchSports()
                    for sport in vm.sports where expandedEvents.contains(sport.key) {
                        try await vm.fetchEvents(for: sport)
                    }
                } catch {
                    // Error is already handled in the view model
                    print("⚠️ Refresh failed:", error)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingSortOptions = true
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
    }
    
    private func toggleSport(_ sport: Sport) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedEvents.contains(sport.key) {
                expandedEvents.remove(sport.key)
            } else {
                expandedEvents.insert(sport.key)
                Task {
                    do {
                        try await vm.fetchEvents(for: sport)
                    } catch {
                        // Error is already handled in the view model
                        print("⚠️ Sport fetch failed:", error)
                    }
                }
            }
        }
    }
}

//  GameBrowserView.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/23/25.
//

