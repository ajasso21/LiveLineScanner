import Foundation

class AlertsViewModel {
    static let shared = AlertsViewModel()
    
    private init() {}
    
    func checkAndFireAlerts(valueIndex: Double) {
        // Implement alert logic here
        // For now, just print the value index
        print("Value index: \(valueIndex)")
    }
} 