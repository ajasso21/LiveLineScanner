import SwiftUI

struct MainView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 0) {
                    // League and Day Pickers
                    VStack(spacing: 8) {
                        LeaguePickerView(selectedLeague: $viewModel.selectedLeague)
                        DayPickerView(selectedDay: $viewModel.selectedDay)
                    }
                    .padding(.vertical, 8)
                    
                    // Schedule List
                    ScheduleListView(
                        games: viewModel.filteredGames,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage
                    )
                }
            }
            .navigationTitle("LiveLine Scanner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - League Picker View
private struct LeaguePickerView: View {
    @Binding var selectedLeague: League
    
    var body: some View {
        Picker("League", selection: $selectedLeague) {
            ForEach(League.allCases, id: \.self) { league in
                Text(league.title)
                    .tag(league)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Day Picker View
private struct DayPickerView: View {
    @Binding var selectedDay: DayOption
    
    var body: some View {
        Picker("Day", selection: $selectedDay) {
            ForEach(DayOption.allCases, id: \.self) { day in
                Text(day.rawValue.capitalized)
                    .tag(day)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Schedule List View
private struct ScheduleListView: View {
    let games: [Game]
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = errorMessage {
                ErrorView(message: error)
            } else if games.isEmpty {
                EmptyStateView()
            } else {
                List(games) { game in
                    GameRowView(game: game)
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Error View
private struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No games scheduled")
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainView()
        .environmentObject(AppViewModel())
} 