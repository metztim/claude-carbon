//
//  ClaudeCarbonApp.swift
//  ClaudeCarbon
//
//  Main application entry point for Claude Carbon menu bar app.
//

import SwiftUI

@main
struct ClaudeCarbonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Services as StateObjects for SwiftUI lifecycle
    @StateObject private var dataStore = DataStore()
    @StateObject private var historyMonitor = HistoryMonitor()

    // SessionCoordinator bridges HistoryMonitor -> TokenEstimator -> DataStore
    // Initialized lazily after StateObjects are ready
    @State private var sessionCoordinator: SessionCoordinator?

    private let energyCalculator = EnergyCalculator()

    var body: some Scene {
        // Menu bar extra - the proper SwiftUI way for macOS 13+
        MenuBarExtra {
            MenuBarView(
                dataStore: dataStore,
                historyMonitor: historyMonitor,
                energyCalculator: energyCalculator
            )
            .onAppear {
                // Initialize coordinator once views are ready
                if sessionCoordinator == nil {
                    sessionCoordinator = SessionCoordinator(
                        dataStore: dataStore,
                        historyMonitor: historyMonitor
                    )
                }
            }
        } label: {
            Image(systemName: "leaf.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
