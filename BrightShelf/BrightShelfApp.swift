//
//  BrightShelfApp.swift
//  BrightShelf
//
//  Created by Linus-Fin Leupold on 25.11.24.
//

import SwiftUI
import AppKit

@main
struct BrightShelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.titlebarAppearsTransparent = true
                        window.titleVisibility = .hidden
                        window.backgroundColor = .clear
                        window.isMovableByWindowBackground = true
                        
                        // Fenster zentrieren
                        window.center()
                        
                        // Abgerundete Ecken
                        window.isOpaque = false
                        window.hasShadow = true
                        
                        // Standard-Titelleiste verstecken aber Kontrollelemente behalten
                        window.styleMask.insert(.fullSizeContentView)
                        
                        // Fenster-Größe festlegen
                        window.setContentSize(NSSize(width: 800, height: 500))
                    }
                }
        }
    }
}
