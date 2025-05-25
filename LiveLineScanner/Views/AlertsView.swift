import SwiftUI
import UserNotifications

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.rules) { $rule in
                    AlertRuleRow(rule: $rule)
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                Button("Send Digest") {
                    viewModel.sendDailyDigest()
                }
                .disabled(viewModel.digestPending.isEmpty)
            }
            .alert("Notifications Disabled",
                   isPresented: $viewModel.showingPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive odds alerts.")
            }
        }
    }
}

struct AlertRuleRow: View {
    @Binding var rule: AlertRule
    @State private var showingSnoozeSheet = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(rule.type.rawValue)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $rule.enabled)
            }
            
            Text("Threshold: \(rule.displayThreshold)")
                .foregroundColor(.secondary)
            
            if let lastFired = rule.lastFired {
                Text("Last fired: \(lastFired.formatted(.relative(presentation: .named)))")
                    .foregroundColor(.secondary)
            }
            
            if rule.isSnoozing,
               let until = rule.snoozeUntil {
                Text("Snoozed until: \(until.formatted(.relative(presentation: .named)))")
                    .foregroundColor(.orange)
            }
        }
        .swipeActions {
            Button {
                showingSnoozeSheet = true
            } label: {
                Label("Snooze", systemImage: "moon.zzz")
            }
            .tint(.orange)
        }
        .confirmationDialog("Snooze Duration",
                          isPresented: $showingSnoozeSheet) {
            Button("1 hour") { AlertsViewModel.shared.snoozeRule(rule, for: 1) }
            Button("4 hours") { AlertsViewModel.shared.snoozeRule(rule, for: 4) }
            Button("8 hours") { AlertsViewModel.shared.snoozeRule(rule, for: 8) }
            Button("24 hours") { AlertsViewModel.shared.snoozeRule(rule, for: 24) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("How long would you like to snooze alerts for \(rule.type.rawValue)?")
        }
    }
}

#Preview {
    AlertsView()
} 