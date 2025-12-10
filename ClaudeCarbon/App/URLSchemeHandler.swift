//
//  URLSchemeHandler.swift
//  ClaudeCarbon
//
//  Handles claudecarbon:// URL scheme for external integration.
//

import Foundation

/// Handles incoming URL scheme events from external sources
class URLSchemeHandler {
    static let shared = URLSchemeHandler()

    // MARK: - Notification Names

    /// Posted when a prompt event is received
    /// UserInfo contains: ["sessionId": String]
    static let promptReceivedNotification = Notification.Name("ClaudeCarbon.PromptReceived")

    /// Posted when a stop event is received
    /// UserInfo contains: ["sessionId": String]
    static let stopReceivedNotification = Notification.Name("ClaudeCarbon.StopReceived")

    // MARK: - Event Types

    enum EventType: String {
        case prompt
        case stop
    }

    // MARK: - URL Handling

    /// Handles a claudecarbon:// URL
    /// - Parameter url: The URL to handle
    ///
    /// Expected format: claudecarbon://event?type=prompt&sessionId=abc123
    func handle(url: URL) {
        guard url.scheme == "claudecarbon" else {
            print("URLSchemeHandler: Invalid scheme '\(url.scheme ?? "nil")', expected 'claudecarbon'")
            return
        }

        let host = url.host ?? ""
        guard host == "event" else {
            print("URLSchemeHandler: Unknown host '\(host)'")
            return
        }

        // Parse URL parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("URLSchemeHandler: Failed to parse URL components")
            return
        }

        // Extract parameters
        var parameters: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                parameters[item.name] = value
            }
        }

        // Extract event type
        guard let typeString = parameters["type"],
              let eventType = EventType(rawValue: typeString) else {
            print("URLSchemeHandler: Missing or invalid 'type' parameter")
            return
        }

        // Extract session ID (accepts both "session" and "sessionId" for compatibility)
        guard let sessionId = parameters["session"] ?? parameters["sessionId"], !sessionId.isEmpty else {
            print("URLSchemeHandler: Missing or empty 'session' parameter")
            return
        }

        // Process event
        processEvent(type: eventType, sessionId: sessionId, parameters: parameters)
    }

    // MARK: - Event Processing

    private func processEvent(type: EventType, sessionId: String, parameters: [String: String]) {
        print("URLSchemeHandler: Processing \(type.rawValue) event for session \(sessionId)")

        let userInfo: [String: Any] = [
            "sessionId": sessionId,
            "parameters": parameters
        ]

        switch type {
        case .prompt:
            NotificationCenter.default.post(
                name: Self.promptReceivedNotification,
                object: self,
                userInfo: userInfo
            )

        case .stop:
            NotificationCenter.default.post(
                name: Self.stopReceivedNotification,
                object: self,
                userInfo: userInfo
            )
        }
    }
}
