import SwiftUI
import UserNotifications

// MARK: - Models
struct AlertRule: Identifiable, Codable {
    enum RuleType: String, Codable, CaseIterable {
        case parlayEV = "Parlay EV"
        case moneyline = "Moneyline"
        case arbitrage = "Arbitrage"
        case valueIndex = "Value Index"
    }
    
    let id: UUID
    var type: RuleType
    var threshold: Double
    var enabled: Bool
    var lastFired: Date?
    var snoozeUntil: Date?
    
    var isSnoozing: Bool {
        guard let snoozeUntil = snoozeUntil else { return false }
        return Date() < snoozeUntil
    }
    
    var displayThreshold: String {
        switch type {
        case .parlayEV, .arbitrage, .valueIndex:
            return "\(Int(threshold * 100))%"
        case .moneyline:
            return String(format: "%.2f", threshold)
        }
    }
}

// MARK: - ViewModel
@MainActor
class AlertsViewModel: ObservableObject {
    static let shared = AlertsViewModel()
    
    @Published var rules: [AlertRule] = [] {
        didSet { saveRules() }
    }
    @Published var digestPending: [AlertRule] = []
    @Published var showingPermissionAlert = false
    
    private let storageKey = "alertRules"
    private let notificationManager = NotificationManager.shared
    
    private init() {
        loadRules()
        requestPermission()
        setupDailyDigest()
    }
    
    // MARK: - Persistence
    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadRules() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([AlertRule].self, from: data) {
            rules = saved
        } else {
            // Initialize default rules
            rules = [
                AlertRule(id: .init(), type: .parlayEV, threshold: 0.05, enabled: true, lastFired: nil),
                AlertRule(id: .init(), type: .moneyline, threshold: 2.0, enabled: true, lastFired: nil),
                AlertRule(id: .init(), type: .arbitrage, threshold: 0.02, enabled: true, lastFired: nil),
                AlertRule(id: .init(), type: .valueIndex, threshold: 0.1, enabled: true, lastFired: nil)
            ]
        }
    }
    
    // MARK: - Notifications
    func requestPermission() {
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
    
    func checkAndFireAlerts(
        parlayEV: Double? = nil,
        moneylineOdds: [Double]? = nil,
        arbitrageMargin: Double? = nil,
        valueIndex: Double? = nil
    ) {
        for i in rules.indices {
            guard rules[i].enabled, !rules[i].isSnoozing else { continue }
            
            let rule = rules[i]
            var shouldFire = false
            
            switch rule.type {
            case .parlayEV:
                if let ev = parlayEV {
                    shouldFire = ev >= rule.threshold
                }
            case .moneyline:
                if let odds = moneylineOdds {
                    shouldFire = odds.contains { $0 >= rule.threshold }
                }
            case .arbitrage:
                if let margin = arbitrageMargin {
                    shouldFire = margin >= rule.threshold
                }
            case .valueIndex:
                if let vi = valueIndex {
                    shouldFire = vi >= rule.threshold
                }
            }
            
            if shouldFire {
                scheduleNotification(for: rule)
                rules[i].lastFired = Date()
                digestPending.append(rules[i])
            }
        }
    }
    
    private func scheduleNotification(for rule: AlertRule) {
        let content = UNMutableNotificationContent()
        content.title = "Odds Alert"
        
        switch rule.type {
        case .parlayEV:
            content.body = "Parlay EV has exceeded \(rule.displayThreshold)"
        case .moneyline:
            content.body = "A moneyline bet exceeded \(rule.displayThreshold)"
        case .arbitrage:
            content.body = "Arbitrage opportunity found with \(rule.displayThreshold) margin"
        case .valueIndex:
            content.body = "Value bet found with \(rule.displayThreshold) edge"
        }
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: rule.id.uuidString,
            content: content,
            trigger: nil // immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Digest & Snooze
    private func setupDailyDigest() {
        // Schedule daily digest at 9 PM
        let content = UNMutableNotificationContent()
        content.title = "Daily Odds Digest"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_digest",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendDailyDigest() {
        guard !digestPending.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Odds Digest"
        content.body = digestPending.map { rule in
            "\(rule.type.rawValue): \(rule.displayThreshold)"
        }.joined(separator: "; ")
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "manual_digest",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        digestPending.removeAll()
    }
    
    func snoozeRule(_ rule: AlertRule, for hours: Int) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].snoozeUntil = Date().addingTimeInterval(Double(hours) * 3600)
        }
    }
}

// MARK: - Views
struct AlertsView: View {
    @StateObject private var vm = AlertsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach($vm.rules) { $rule in
                        AlertRuleRow(rule: $rule, vm: vm)
                    }
                    .onDelete { idx in
                        vm.rules.remove(atOffsets: idx)
                    }
                } header: {
                    Text("Alert Rules")
                } footer: {
                    Text("Set thresholds for different types of betting opportunities.")
                }
                
                Button("Add Rule") {
                    let new = AlertRule(
                        id: .init(),
                        type: .parlayEV,
                        threshold: 0.1,
                        enabled: true,
                        lastFired: nil
                    )
                    vm.rules.append(new)
                }
            }
            .navigationTitle("Smart Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Digest") {
                        vm.sendDailyDigest()
                    }
                }
            }
            .alert("Notifications Disabled",
                   isPresented: $vm.showingPermissionAlert) {
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
    @ObservedObject var vm: AlertsViewModel
    @State private var showingSnoozeOptions = false
    
    private let snoozeOptions = [1, 4, 8, 24]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Type", selection: $rule.type) {
                    ForEach(AlertRule.RuleType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Spacer()
                
                Toggle("Enabled", isOn: $rule.enabled)
                    .labelsHidden()
            }
            
            HStack {
                TextField("Threshold", value: $rule.threshold, format: .percent)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                
                Spacer()
                
                if let lastFired = rule.lastFired {
                    Text(lastFired, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Menu {
                    ForEach(snoozeOptions, id: \.self) { hours in
                        Button("Snooze \(hours)h") {
                            withAnimation {
                                vm.snoozeRule(rule, for: hours)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "bell.slash")
                        .foregroundColor(rule.isSnoozing ? .orange : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AlertsView()
} 