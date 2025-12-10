import Foundation

/// Model representing a Claude Code session
struct Session: Codable, Identifiable {
    let id: UUID
    let sessionId: String
    let projectPath: String?
    var startTime: Date
    var lastActivityTime: Date
    var inputTokens: Int
    var outputTokens: Int
    let modelName: String
    var actualModel: String?

    init(
        id: UUID = UUID(),
        sessionId: String,
        projectPath: String? = nil,
        startTime: Date = Date(),
        lastActivityTime: Date = Date(),
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        modelName: String = "sonnet",
        actualModel: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.projectPath = projectPath
        self.startTime = startTime
        self.lastActivityTime = lastActivityTime
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.modelName = modelName
        self.actualModel = actualModel
    }

    var totalTokens: Int {
        inputTokens + outputTokens
    }
}
