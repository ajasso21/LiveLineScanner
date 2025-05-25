import SwiftUI

// MARK: - Detail Row Modifier
struct DetailRowModifier: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            content
        }
    }
}

extension View {
    func detailRow(label: String) -> some View {
        modifier(DetailRowModifier(label: label))
    }
}

// MARK: - Teams Section View
struct TeamsSection: View {
    let event: Event
    
    var body: some View {
        Section(header: Text("Teams")) {
            ForEach([
                ("Home", event.homeTeam),
                ("Away", event.awayTeam)
            ], id: \.0) { label, value in
                Text(value)
                    .detailRow(label: label)
            }
            
            if let scores = event.scores {
                ForEach([
                    ("Home Score", String(format: "%.0f", scores["home"] ?? 0)),
                    ("Away Score", String(format: "%.0f", scores["away"] ?? 0))
                ], id: \.0) { label, value in
                    Text(value)
                        .detailRow(label: label)
                }
            }
        }
    }
}

// MARK: - Schedule Section View
struct ScheduleSection: View {
    let event: Event
    
    var body: some View {
        Section(header: Text("Schedule")) {
            Text(event.commenceTime, style: .date)
                .detailRow(label: "Date")
            
            if let lastUpdate = event.lastUpdate {
                Text(lastUpdate, style: .relative)
                    .detailRow(label: "Last Update")
            }
            
            Text(event.completed ? "Completed" : "Upcoming")
                .detailRow(label: "Status")
        }
    }
}

// MARK: - Notifications Section View
struct NotificationsSection: View {
    let event: Event
    let hasNotification: Bool
    let onNotificationRequest: () async -> Void
    let onNotificationCancel: () -> Void
    
    var body: some View {
        Section(header: Text("Notifications")) {
            if event.completed {
                Text("Game has ended")
                    .foregroundStyle(.secondary)
            } else if hasNotification {
                Button(role: .destructive) {
                    onNotificationCancel()
                } label: {
                    Label("Remove Notification", systemImage: "bell.slash.fill")
                }
            } else {
                Button {
                    Task {
                        await onNotificationRequest()
                    }
                } label: {
                    Label("Notify Me", systemImage: "bell.badge")
                }
            }
        }
    }
}

// MARK: - Event Details View
struct EventDetailsView: View {
    // MARK: - Properties
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: GameBrowserViewModel
    @StateObject private var notificationManager = NotificationManager.shared
    
    // MARK: - State
    @State private var showingNotificationAlert = false
    @State private var notificationError: String?
    @State private var hasNotification = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                TeamsSection(event: event)
                ScheduleSection(event: event)
                NotificationsSection(
                    event: event,
                    hasNotification: hasNotification,
                    onNotificationRequest: handleNotificationRequest,
                    onNotificationCancel: { notificationManager.cancelNotification(for: event) }
                )
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Notification Error", isPresented: $showingNotificationAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                if let error = notificationError {
                    Text(error)
                }
            })
            .task {
                await checkNotificationStatus()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleNotificationRequest() async {
        if await notificationManager.scheduleNotification(for: event) {
            await checkNotificationStatus()
        } else {
            notificationError = "Failed to schedule notification. Please check your notification settings."
            showingNotificationAlert = true
        }
    }
    
    private func checkNotificationStatus() async {
        hasNotification = await notificationManager.hasNotification(for: event.id)
    }
}
