import SwiftUI

struct ContentView: View {
    @StateObject private var gameBrowserVM = GameBrowserViewModel()
    
    var body: some View {
        TabView {
            GameBrowserView()
                .environmentObject(gameBrowserVM)
                .tabItem {
                    Label("Games & Odds", systemImage: "sportscourt")
                }
            
            PropBetView()
                .tabItem {
                    Label("Props", systemImage: "person.fill")
                }
            
            OddsComparisonView()
                .environmentObject(gameBrowserVM)
                .tabItem {
                    Label("Compare Odds", systemImage: "chart.bar")
                }
        }
        .enableBackgroundRefresh()
    }
}

#Preview {
    ContentView()
} 