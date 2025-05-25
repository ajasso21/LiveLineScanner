import SwiftUI
import UIKit

/// Wraps our CustomUIKitView for use in SwiftUI.
struct CustomUIKitViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomUIKitView {
        let view = CustomUIKitView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: CustomUIKitView, context: Context) {
        // Update view properties here if needed
        uiView.setNeedsDisplay()
    }
}
//  CustomUIKitViewRepresentable.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/25/25.
//

import Foundation
