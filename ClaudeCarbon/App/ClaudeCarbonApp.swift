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

    // SessionJSONLMonitor needs DataStore at init, so initialized lazily
    @State private var sessionJSONLMonitor: SessionJSONLMonitor?

    // SessionCoordinator bridges HistoryMonitor + SessionJSONLMonitor -> DataStore
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
                // Initialize services once views are ready
                if sessionJSONLMonitor == nil {
                    sessionJSONLMonitor = SessionJSONLMonitor(dataStore: dataStore)
                }
                if sessionCoordinator == nil, let monitor = sessionJSONLMonitor {
                    sessionCoordinator = SessionCoordinator(
                        dataStore: dataStore,
                        historyMonitor: historyMonitor,
                        sessionJSONLMonitor: monitor
                    )
                }
            }
        } label: {
            Image(systemName: "leaf.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
