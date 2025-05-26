//
//  LiveLineScannerApp.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/22/25.
//

import SwiftUI

@main
struct LiveLineScannerApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    init() {
        // Configure app appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure list appearance
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .task {
                    await viewModel.loadSchedule()
                }
                .preferredColorScheme(.dark)
        }
    }
}
