# LiveLineScanner

A modern iOS app for tracking and analyzing sports betting odds.

## Project Structure

```
LiveLineScanner/
├── Core/                    # Core app files
│   └── LiveLineScannerApp.swift
├── Views/                   # All SwiftUI views
│   ├── Main/               # Main navigation views
│   │   ├── MainTabView.swift
│   │   └── ContentView.swift
│   ├── Odds/               # Odds-related views
│   │   ├── OddsComparisonView.swift
│   │   └── OddsDetailView.swift
│   ├── Betting/            # Betting-related views
│   │   ├── BetTrackerView.swift
│   │   └── PropBetView.swift
│   ├── Tools/              # Tool views
│   │   ├── ToolsView.swift
│   │   └── ParlayBuilderView.swift
│   ├── Settings/           # Settings views
│   │   └── SettingsView.swift
│   └── Components/         # Reusable view components
│       ├── GameCard.swift
│       ├── OddsDisplay.swift
│       └── BetSlip.swift
├── Services/               # Service layer
│   └── SportradarOddsService.swift
├── Models/                 # Data models
│   └── OddsUpdate.swift
├── ViewModels/            # View models
├── Extensions/            # Swift extensions
├── Theme/                 # Theme and styling
│   ├── AppTheme.swift
│   └── Colors.xcassets/
├── Cache/                 # Caching layer
└── Resources/            # App resources
    ├── Assets.xcassets/
    └── LiveLineScanner.xcdatamodeld/
```

## Features

- Live odds tracking
- Odds comparison across bookmakers
- Prop bet analysis
- Bet tracking and statistics
- Advanced betting tools
- Customizable UI themes

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Dependencies

- Hero: For smooth transitions
- SwiftUICharts: For data visualization

## Installation

1. Clone the repository
2. Open `LiveLineScanner.xcodeproj` in Xcode
3. Build and run the project

## License

This project is licensed under the MIT License - see the LICENSE file for details. 