import SwiftUI

// MARK: - Supporting Views
struct FavoritesSectionView: View {
    let sports: [SportType]
    let favorites: Set<String>
    let expandedEvents: Set<String>
    let sortedEventsForSport: (String) -> [Event]
    let onEventTap: (Event) -> Void
    let onSportTap: (SportType) -> Void
    
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

struct AllSportsSectionView: View {
    let sports: [SportType]
    let favorites: Set<String>
    let expandedEvents: Set<String>
    let sortedEventsForSport: (String) -> [Event]
    let onEventTap: (Event) -> Void
    let onSportTap: (SportType) -> Void
    
    var body: some View {
        Section("All Sports") {
            ForEach(sports.filter { !favorites.contains($0.key) }) { sport in
                SportRow(
                    sport: sport,
                    events: sortedEventsForSport(sport.key),
                    isExpanded: expandedEvents.contains(sport.key),
                    isFavorite: false,
                    onEventTap: onEventTap
                )
                .sportRowStyle(isExpanded: expandedEvents.contains(sport.key))
                .onTapGesture { onSportTap(sport) }
            }
        }
    }
}

// MARK: - Main View
struct GameBrowserView: View {
    @EnvironmentObject private var viewModel: GameBrowserViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSettings = false
    @State private var showEventDetail: Event?
    @State private var favorites: Set<String> = []
    @State private var expandedSports: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                if !favorites.isEmpty {
                    FavoritesSectionView(
                        sports: viewModel.sports,
                        favorites: favorites,
                        expandedEvents: expandedSports,
                        sortedEventsForSport: viewModel.sortedEvents,
                        onEventTap: { event in
                            showEventDetail = event
                        },
                        onSportTap: toggleFavorite
                    )
                }
                
                AllSportsSectionView(
                    sports: viewModel.sports,
                    favorites: favorites,
                    expandedEvents: expandedSports,
                    sortedEventsForSport: viewModel.sortedEvents,
                    onEventTap: { event in
                        showEventDetail = event
                    },
                    onSportTap: toggleFavorite
                )
            }
            .navigationTitle("Live Lines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $showEventDetail) { event in
                OddsDetailView(event: event, viewModel: viewModel)
            }
            .task {
                do {
                    try await viewModel.fetchSports()
                } catch {
                    print("Failed to fetch sports:", error)
                }
            }
        }
    }
    
    private func toggleFavorite(_ sport: SportType) {
        if favorites.contains(sport.key) {
            favorites.remove(sport.key)
        } else {
            favorites.insert(sport.key)
        }
    }
}

#Preview {
    let viewModel = GameBrowserViewModel()
    return GameBrowserView()
        .environmentObject(viewModel)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

//  GameBrowserView.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/23/25.
//

