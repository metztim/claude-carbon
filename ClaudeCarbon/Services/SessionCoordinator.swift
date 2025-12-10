//
//  SessionCoordinator.swift
//  ClaudeCarbon
//
//  Coordinates between HistoryMonitor, TokenEstimator, and DataStore
//  to track token usage across Claude Code sessions.
//

import Foundation
import Combine

/// Bridges HistoryMonitor prompt detection with DataStore session tracking.
/// Listens for new prompts, estimates tokens, and updates session records.
class SessionCoordinator: ObservableObject {
    private let dataStore: DataStore
    private let historyMonitor: HistoryMonitor
    private let tokenEstimator: TokenEstimator

    private var cancellables = Set<AnyCancellable>()
    private var lastProcessedPrompt: String?

    init(dataStore: DataStore, historyMonitor: HistoryMonitor, tokenEstimator: TokenEstimator = TokenEstimator()) {
        self.dataStore = dataStore
        self.historyMonitor = historyMonitor
        self.tokenEstimator = tokenEstimator

        setupBindings()
        print("SessionCoordinator: Initialized and listening for prompts")
    }

    private func setupBindings() {
        // Listen for prompt text changes from HistoryMonitor
        historyMonitor.$lastPromptText
            .compactMap { $0 }
            .sink { [weak self] promptText in
                self?.handleNewPrompt(text: promptText)
            }
            .store(in: &cancellables)

        // Also listen for session changes to ensure we have a session record
        historyMonitor.$currentSessionId
            .compactMap { $0 }
            .sink { [weak self] sessionId in
                self?.ensureSessionExists(sessionId: sessionId)
            }
            .store(in: &cancellables)
    }

    private func handleNewPrompt(text: String) {
        // Avoid processing the same prompt twice
        guard text != lastProcessedPrompt else { return }
        lastProcessedPrompt = text

        guard let sessionId = historyMonitor.currentSessionId else {
            print("SessionCoordinator: No session ID available for prompt")
            return
        }

        // Estimate tokens
        let tokenEstimate = tokenEstimator.estimateTotalTokens(from: text)

        print("SessionCoordinator: New prompt - Input: \(tokenEstimate.input), Output: \(tokenEstimate.output), Total: \(tokenEstimate.total)")

        // Update or create session
        if var session = dataStore.getSession(byClaudeSessionId: sessionId) {
            // Update existing session
            session.inputTokens += tokenEstimate.input
            session.estimatedOutputTokens += tokenEstimate.output
            session.lastActivityTime = Date()
            dataStore.updateSession(session)
            print("SessionCoordinator: Updated session \(sessionId) - Total tokens: \(session.totalTokens)")
        } else {
            // Create new session
            let newSession = Session(
                sessionId: sessionId,
                projectPath: nil,
                startTime: historyMonitor.lastPromptTime ?? Date(),
                lastActivityTime: Date(),
                inputTokens: tokenEstimate.input,
                estimatedOutputTokens: tokenEstimate.output
            )
            dataStore.saveSession(newSession)
            print("SessionCoordinator: Created new session \(sessionId)")
        }
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
                estimatedOutputTokens: 0
            )
            dataStore.saveSession(newSession)
            print("SessionCoordinator: Pre-created session record for \(sessionId)")
        }
    }
}
