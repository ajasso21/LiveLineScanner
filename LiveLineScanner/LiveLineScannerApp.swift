//
//  LiveLineScannerApp.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/22/25.
//

import SwiftUI

@main
struct LiveLineScannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
