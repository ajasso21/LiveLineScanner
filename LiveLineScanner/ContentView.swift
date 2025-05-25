import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GameBrowserView()
                .tabItem {
                    Label("Games & Odds", systemImage: "sportscourt")
                }
            
            PropBetView()
                .tabItem {
                    Label("Props", systemImage: "person.fill")
                }
            
            OddsComparisonView()
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