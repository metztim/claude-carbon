//
//  ActivityIndicator.swift
//  ClaudeCarbon
//
//  Tracks token consumption activity for menu bar icon animation.
//

import Foundation
import Combine

/// Tracks whether Claude is actively consuming tokens for UI feedback
class ActivityIndicator: ObservableObject {
    @Published var isActive: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var deactivationTimer: Timer?
    private let activeDuration: TimeInterval = 2.0

    /// Connect to SessionJSONLMonitor to receive token updates
    func connect(to monitor: SessionJSONLMonitor) {
        monitor.$tokenUpdate
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerActivity()
            }
            .store(in: &cancellables)
    }

    private func triggerActivity() {
        // Cancel existing timer to extend active window
        deactivationTimer?.invalidate()

        isActive = true

        // Schedule deactivation
        deactivationTimer = Timer.scheduledTimer(
            withTimeInterval: activeDuration,
            repeats: false
        ) { [weak self] _ in
            self?.isActive = false
        }
    }
}
