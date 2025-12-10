import Foundation
import Combine

/// Monitors ~/.claude/history.jsonl for new Claude Code prompt entries
class HistoryMonitor: ObservableObject {
    // MARK: - Published Properties

    @Published var currentSessionId: String?
    @Published var lastPromptText: String?
    @Published var lastPromptTime: Date?

    // MARK: - Private Properties

    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var lastOffset: UInt64 = 0
    private let historyPath: String
    private let monitorQueue = DispatchQueue(label: "com.claudecarbon.historymonitor", qos: .utility)

    // MARK: - Constants

    private static let notificationName = Notification.Name("NewPromptDetected")

    // MARK: - Initialization

    init() {
        // Get the real home directory (not the sandbox container)
        let realHomeDirectory: String
        if let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir {
            realHomeDirectory = String(cString: homeDir)
        } else {
            realHomeDirectory = NSHomeDirectory() // Fallback
        }
        self.historyPath = realHomeDirectory + "/.claude/history.jsonl"
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Stop and restart monitoring (useful for testing or recovery)
    func restartMonitoring() {
        stopMonitoring()
        startMonitoring()
    }

    // MARK: - Private Methods

    private func startMonitoring() {
        monitorQueue.async { [weak self] in
            guard let self = self else { return }

            // Check if file exists
            guard FileManager.default.fileExists(atPath: self.historyPath) else {
                print("HistoryMonitor: history.jsonl not found at \(self.historyPath)")
                print("HistoryMonitor: Claude Code may not be installed or history file not yet created")
                return
            }

            // Open file handle
            guard let fileHandle = FileHandle(forReadingAtPath: self.historyPath) else {
                print("HistoryMonitor: Failed to open file handle for \(self.historyPath)")
                return
            }

            self.fileHandle = fileHandle

            // Get current file size and position at end
            do {
                let currentSize = try fileHandle.seekToEnd()
                self.lastOffset = currentSize
                print("HistoryMonitor: Starting monitoring from offset \(currentSize)")
            } catch {
                print("HistoryMonitor: Failed to seek to end: \(error)")
                return
            }

            // Create dispatch source for file monitoring
            let fileDescriptor = fileHandle.fileDescriptor
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: [.write, .extend, .delete, .rename],
                queue: self.monitorQueue
            )

            source.setEventHandler { [weak self] in
                self?.handleFileChange()
            }

            source.setCancelHandler { [weak self] in
                try? self?.fileHandle?.close()
                self?.fileHandle = nil
            }

            self.source = source
            source.resume()

            print("HistoryMonitor: Started monitoring \(self.historyPath)")
        }
    }

    private func stopMonitoring() {
        source?.cancel()
        source = nil
        fileHandle = nil
        print("HistoryMonitor: Stopped monitoring")
    }

    private func handleFileChange() {
        guard let fileHandle = fileHandle else { return }

        do {
            // Get current file size
            let currentSize = try fileHandle.seekToEnd()

            // Check for file truncation/rotation
            if currentSize < lastOffset {
                print("HistoryMonitor: File truncated or rotated (was \(lastOffset), now \(currentSize))")
                lastOffset = 0
            }

            // Check if there's new data
            guard currentSize > lastOffset else {
                return
            }

            // Seek to last read position
            try fileHandle.seek(toOffset: lastOffset)

            // Read new data
            let newData = fileHandle.readDataToEndOfFile()
            lastOffset = currentSize

            // Parse new lines
            guard let content = String(data: newData, encoding: .utf8) else {
                print("HistoryMonitor: Failed to decode new data as UTF-8")
                return
            }

            // Split into lines and process each
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }

                parseAndNotify(jsonLine: trimmed)
            }

        } catch {
            print("HistoryMonitor: Error reading file: \(error)")
        }
    }

    private func parseAndNotify(jsonLine: String) {
        guard let jsonData = jsonLine.data(using: .utf8) else {
            print("HistoryMonitor: Failed to convert line to data")
            return
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("HistoryMonitor: Failed to parse JSON as dictionary")
                return
            }

            // Extract fields
            let display = json["display"] as? String
            let timestampMs = json["timestamp"] as? Double
            let project = json["project"] as? String
            let sessionId = json["sessionId"] as? String

            // Convert timestamp from milliseconds to Date
            let timestamp: Date? = timestampMs.map { Date(timeIntervalSince1970: $0 / 1000.0) }

            // Update published properties on main thread
            DispatchQueue.main.async { [weak self] in
                if let text = display {
                    self?.lastPromptText = text
                }
                if let time = timestamp {
                    self?.lastPromptTime = time
                }
                if let session = sessionId {
                    self?.currentSessionId = session
                }
            }

            // Post notification with parsed data
            let userInfo: [String: Any] = [
                "display": display as Any,
                "timestamp": timestamp as Any,
                "project": project as Any,
                "sessionId": sessionId as Any
            ]

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.notificationName,
                    object: self,
                    userInfo: userInfo
                )
            }

            print("HistoryMonitor: New prompt detected - Session: \(sessionId ?? "nil"), Text: \(display?.prefix(50) ?? "nil")...")

        } catch {
            print("HistoryMonitor: Failed to parse JSON: \(error)")
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let newPromptDetected = Notification.Name("NewPromptDetected")
}
