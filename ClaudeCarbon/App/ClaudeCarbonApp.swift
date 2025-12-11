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
    @StateObject private var activityIndicator = ActivityIndicator()

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
                energyCalculator: energyCalculator
            )
            .onAppear {
                // Initialize SessionCoordinator when menu opens (needs monitor from label's .task)
                if sessionCoordinator == nil, let monitor = sessionJSONLMonitor {
                    sessionCoordinator = SessionCoordinator(
                        dataStore: dataStore,
                        historyMonitor: historyMonitor,
                        sessionJSONLMonitor: monitor
                    )
                }
            }
        } label: {
            MenuBarIconView(activityIndicator: activityIndicator)
                .task {
                    // Initialize monitoring on app launch (not on menu click)
                    if sessionJSONLMonitor == nil {
                        let monitor = SessionJSONLMonitor(dataStore: dataStore)
                        sessionJSONLMonitor = monitor
                        activityIndicator.connect(to: monitor)
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}
