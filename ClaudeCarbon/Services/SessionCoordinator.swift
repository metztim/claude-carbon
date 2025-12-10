//
//  SessionCoordinator.swift
//  ClaudeCarbon
//
//  Coordinates between HistoryMonitor, SessionJSONLMonitor, and DataStore
//  to track actual token usage across Claude Code sessions.
//

import Foundation
import Combine

/// Bridges HistoryMonitor and SessionJSONLMonitor with DataStore session tracking.
/// Listens for session creation from HistoryMonitor and actual tokens from SessionJSONLMonitor.
class SessionCoordinator: ObservableObject {
    private let dataStore: DataStore
    private let historyMonitor: HistoryMonitor
    private let sessionJSONLMonitor: SessionJSONLMonitor

    private var cancellables = Set<AnyCancellable>()

    init(dataStore: DataStore, historyMonitor: HistoryMonitor, sessionJSONLMonitor: SessionJSONLMonitor) {
        self.dataStore = dataStore
        self.historyMonitor = historyMonitor
        self.sessionJSONLMonitor = sessionJSONLMonitor

        setupBindings()
        print("SessionCoordinator: Initialized with actual token tracking")
    }

    private func setupBindings() {
        // Listen for session changes from HistoryMonitor to ensure session records exist
        historyMonitor.$currentSessionId
            .compactMap { $0 }
            .sink { [weak self] sessionId in
                self?.ensureSessionExists(sessionId: sessionId)
            }
            .store(in: &cancellables)

        // Listen for actual token updates from SessionJSONLMonitor
        sessionJSONLMonitor.$tokenUpdate
            .compactMap { $0 }
            .sink { [weak self] update in
                self?.handleActualTokens(update)
            }
            .store(in: &cancellables)
    }

    private func handleActualTokens(_ update: SessionJSONLMonitor.TokenUpdate) {
        // Add actual tokens to the session with actual timestamp for correct date filtering
        dataStore.addActualTokens(
            sessionId: update.sessionId,
            inputTokens: update.inputTokens,
            outputTokens: update.outputTokens,
            model: update.model,
            timestamp: update.timestamp
        )
        print("SessionCoordinator: Recorded actual tokens for session \(update.sessionId) - Input: \(update.inputTokens), Output: \(update.outputTokens)")
    }

    private func ensureSessionExists(sessionId: String) {
        // Create session record if it doesn't exist yet
        if dataStore.getSession(byClaudeSessionId: sessionId) == nil {
            let newSession = Session(
                sessionId: sessionId,
                projectPath: nil,
                startTime: historyMonitor.lastPromptTime ?? Date(),
                lastActivityTime: Date(),
                inputTokens: 0,
                outputTokens: 0
            )
            dataStore.saveSession(newSession)
            print("SessionCoordinator: Pre-created session record for \(sessionId)")
        }
    }
}
