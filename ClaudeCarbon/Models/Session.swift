import Foundation

/// Model representing a Claude Code session
struct Session: Codable, Identifiable {
    let id: UUID
    let sessionId: String
    let projectPath: String?
    let startTime: Date
    var lastActivityTime: Date
    var inputTokens: Int
    var estimatedOutputTokens: Int
    let modelName: String

    init(
        id: UUID = UUID(),
        sessionId: String,
        projectPath: String? = nil,
        startTime: Date = Date(),
        lastActivityTime: Date = Date(),
        inputTokens: Int = 0,
        estimatedOutputTokens: Int = 0,
        modelName: String = "sonnet"
    ) {
        self.id = id
        self.sessionId = sessionId
        self.projectPath = projectPath
        self.startTime = startTime
        self.lastActivityTime = lastActivityTime
        self.inputTokens = inputTokens
        self.estimatedOutputTokens = estimatedOutputTokens
        self.modelName = modelName
    }

    var totalTokens: Int {
        inputTokens + estimatedOutputTokens
    }
}
