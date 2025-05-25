// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @StateObject private var gameBrowserVM = GameBrowserViewModel()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "AccentColor")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "AccentColor")!]
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView {
            // 1) Live Visualization Dashboard
            LiveVisualizationView()
                .tabItem {
                    Label("Live Data", systemImage: "livephoto")
                }
            
            // 2) Your live-line scanner value moves
            ContentView()
                .environmentObject(gameBrowserVM)
                .tabItem {
                    Label("Value Moves", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            // 3) Prop Bet Analyzer
            PropBetView()
                .tabItem {
                    Label("Prop Analyzer", systemImage: "dice")
                }
            
            // 4) Game browser & detailed odds
            GameBrowserView()
                .environmentObject(gameBrowserVM)
                .tabItem {
                    Label("Games & Odds", systemImage: "sportscourt")
                }
            
            // 5) Odds Comparison Aggregator
            OddsComparisonView()
                .environmentObject(gameBrowserVM)
                .tabItem {
                    Label("Compare Odds", systemImage: "chart.bar")
                }
            
            // 6) Parlay Builder
            ParlayBuilderView()
                .tabItem {
                    Label("Parlay Builder", systemImage: "square.and.arrow.down.on.square")
                }
            
            // 7) Smart Alerts
            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
        }
    }
}