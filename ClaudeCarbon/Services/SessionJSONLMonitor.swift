//
//  SessionJSONLMonitor.swift
//  ClaudeCarbon
//
//  Monitors Claude Code session JSONL files for actual token usage data.
//  Reads from ~/.claude/projects/{encoded-path}/{sessionId}.jsonl
//

import Foundation
import Combine

/// Monitors project-specific JSONL files for actual token usage from Claude API responses
class SessionJSONLMonitor: ObservableObject {
    // MARK: - Published Properties

    @Published var tokenUpdate: TokenUpdate?

    // MARK: - Types

    struct TokenUpdate {
        let sessionId: String
        let model: String
        let inputTokens: Int
        let outputTokens: Int
        let timestamp: Date
    }

    // MARK: - Private Properties

    private var projectsPath: String
    private var monitoredFiles: [String: FileMonitor] = [:]
    private var directorySource: DispatchSourceFileSystemObject?
    private var directoryFd: Int32 = -1
    private let monitorQueue = DispatchQueue(label: "com.claudecarbon.sessionjsonl", qos: .utility)
    private let dataStore: DataStore

    // Track file offsets per JSONL file (in-memory cache, persisted to dataStore)
    private var fileOffsets: [String: UInt64] = [:]

    // Track monitored subdirectories (project directories)
    private var monitoredDirectories: [String: SubdirectoryMonitor] = [:]

    // MARK: - Initialization

    init(dataStore: DataStore) {
        self.dataStore = dataStore

        let realHomeDirectory: String
        if let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir {
            realHomeDirectory = String(cString: homeDir)
        } else {
            realHomeDirectory = NSHomeDirectory()
        }
        self.projectsPath = realHomeDirectory + "/.claude/projects"

        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        monitorQueue.async { [weak self] in
            self?.cleanupOrphanedOffsets()
            self?.setupDirectoryMonitoring()
            self?.scanExistingProjects()
        }
    }

    /// Clean up SQLite offset entries for files that no longer exist
    private func cleanupOrphanedOffsets() {
        let storedPaths = dataStore.getAllOffsetPaths()
        var cleanedCount = 0

        for path in storedPaths {
            if !FileManager.default.fileExists(atPath: path) {
                dataStore.deleteOffset(forFile: path)
                cleanedCount += 1
            }
        }

        if cleanedCount > 0 {
            print("SessionJSONLMonitor: Cleaned up \(cleanedCount) orphaned offset entries")
        }
    }

    func stopMonitoring() {
        directorySource?.cancel()
        directorySource = nil
        if directoryFd >= 0 {
            Darwin.close(directoryFd)
            directoryFd = -1
        }

        for (_, monitor) in monitoredFiles {
            monitor.stop()
        }
        monitoredFiles.removeAll()

        for (_, monitor) in monitoredDirectories {
            monitor.stop()
        }
        monitoredDirectories.removeAll()
        print("SessionJSONLMonitor: Stopped monitoring")
    }

    // MARK: - Private Methods

    private func setupDirectoryMonitoring() {
        guard FileManager.default.fileExists(atPath: projectsPath) else {
            print("SessionJSONLMonitor: Projects directory not found at \(projectsPath)")
            return
        }

        // Use open() syscall directly - FileHandle doesn't work for directories
        let fd = Darwin.open(projectsPath, O_RDONLY | O_EVTONLY)
        guard fd >= 0 else {
            print("SessionJSONLMonitor: Failed to open projects directory (errno: \(errno))")
            return
        }

        directoryFd = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .link],
            queue: monitorQueue
        )

        source.setEventHandler { [weak self] in
            self?.scanExistingProjects()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.directoryFd, fd >= 0 {
                Darwin.close(fd)
                self?.directoryFd = -1
            }
        }

        directorySource = source
        source.resume()

        print("SessionJSONLMonitor: Started directory monitoring at \(projectsPath)")
    }

    private func scanExistingProjects() {
        let fileManager = FileManager.default

        guard let projectDirs = try? fileManager.contentsOfDirectory(atPath: projectsPath) else {
            return
        }

        for projectDir in projectDirs {
            let projectPath = (projectsPath as NSString).appendingPathComponent(projectDir)

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            // Start monitoring this project subdirectory for new JSONL files
            if monitoredDirectories[projectPath] == nil {
                startMonitoringDirectory(atPath: projectPath)
            }

            // Scan for JSONL files in this project directory
            scanProjectDirectory(atPath: projectPath)
        }
    }

    private func scanProjectDirectory(atPath projectPath: String) {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(atPath: projectPath) else {
            return
        }

        for file in files {
            // Skip agent JSONL files - they contain parent session's ID in content
            guard file.hasSuffix(".jsonl") && !file.hasPrefix("agent-") else { continue }

            let filePath = (projectPath as NSString).appendingPathComponent(file)

            // Only start monitoring if not already monitoring this file
            if monitoredFiles[filePath] == nil {
                startMonitoringFile(atPath: filePath)
            }
        }
    }

    private func startMonitoringDirectory(atPath path: String) {
        let monitor = SubdirectoryMonitor(path: path, queue: monitorQueue) { [weak self] in
            self?.scanProjectDirectory(atPath: path)
        }

        if monitor.start() {
            monitoredDirectories[path] = monitor
            print("SessionJSONLMonitor: Started monitoring directory \(path)")
        }
    }

    private func startMonitoringFile(atPath path: String) {
        let monitor = FileMonitor(path: path, queue: monitorQueue) { [weak self] in
            self?.readNewEntries(fromPath: path)
        }

        if monitor.start() {
            monitoredFiles[path] = monitor

            // Load persisted offset from database (0 if first time = reads all history)
            let storedOffset = dataStore.getOffset(forFile: path)
            fileOffsets[path] = storedOffset

            // Immediately read any entries since last stored offset
            readNewEntries(fromPath: path)

            print("SessionJSONLMonitor: Started monitoring \(path) from offset \(storedOffset)")
        }
    }

    private func readNewEntries(fromPath path: String) {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            // File no longer exists - clean up
            if let monitor = monitoredFiles.removeValue(forKey: path) {
                monitor.stop()
                print("SessionJSONLMonitor: Cleaned up monitor for deleted file \(path)")
            }
            fileOffsets.removeValue(forKey: path)
            dataStore.deleteOffset(forFile: path)
            return
        }

        defer { try? handle.close() }

        // Get current offset or start from beginning
        let offset = fileOffsets[path] ?? 0

        // Get current file size
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let currentSize = attrs[.size] as? UInt64 else {
            return
        }

        // Handle file truncation - reset offset and persist
        if currentSize < offset {
            fileOffsets[path] = 0
            dataStore.setOffset(forFile: path, offset: 0)
            return
        }

        guard currentSize > offset else {
            return
        }

        // Seek to last read position
        do {
            try handle.seek(toOffset: offset)
        } catch {
            print("SessionJSONLMonitor: Failed to seek: \(error)")
            return
        }

        // Read new data
        let newData = handle.readDataToEndOfFile()
        fileOffsets[path] = currentSize
        dataStore.setOffset(forFile: path, offset: currentSize)

        guard let content = String(data: newData, encoding: .utf8) else {
            return
        }

        // Parse each line
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if let update = parseTokenUpdate(from: trimmed) {
                DispatchQueue.main.async { [weak self] in
                    self?.tokenUpdate = update
                }
            }
        }
    }

    private func parseTokenUpdate(from jsonLine: String) -> TokenUpdate? {
        guard let data = jsonLine.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Only process assistant messages with usage data
        guard let type = json["type"] as? String, type == "assistant" else {
            return nil
        }

        guard let sessionId = json["sessionId"] as? String else {
            return nil
        }

        guard let message = json["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any] else {
            return nil
        }

        // Extract token counts
        let inputTokens = usage["input_tokens"] as? Int ?? 0
        let outputTokens = usage["output_tokens"] as? Int ?? 0

        // Extract model name
        let model = message["model"] as? String ?? "unknown"

        // Parse timestamp
        let timestamp: Date
        if let timestampStr = json["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            timestamp = formatter.date(from: timestampStr) ?? Date()
        } else {
            timestamp = Date()
        }

        print("SessionJSONLMonitor: Token update - Session: \(sessionId), Model: \(model), Input: \(inputTokens), Output: \(outputTokens)")

        return TokenUpdate(
            sessionId: sessionId,
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            timestamp: timestamp
        )
    }
}

// MARK: - FileMonitor Helper

private class FileMonitor {
    private let path: String
    private let queue: DispatchQueue
    private let onChange: () -> Void

    private var source: DispatchSourceFileSystemObject?
    private var fileHandle: FileHandle?

    init(path: String, queue: DispatchQueue, onChange: @escaping () -> Void) {
        self.path = path
        self.queue = queue
        self.onChange = onChange
    }

    func start() -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            return false
        }

        fileHandle = handle

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: handle.fileDescriptor,
            eventMask: [.write, .extend],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.onChange()
        }

        source.setCancelHandler { [weak self] in
            try? self?.fileHandle?.close()
            self?.fileHandle = nil
        }

        self.source = source
        source.resume()

        return true
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}

// MARK: - SubdirectoryMonitor Helper

/// Monitors a directory for new files (used for project subdirectories)
private class SubdirectoryMonitor {
    private let path: String
    private let queue: DispatchQueue
    private let onChange: () -> Void

    private var source: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1

    init(path: String, queue: DispatchQueue, onChange: @escaping () -> Void) {
        self.path = path
        self.queue = queue
        self.onChange = onChange
    }

    func start() -> Bool {
        // Use open() syscall directly for directories
        let fd = Darwin.open(path, O_RDONLY | O_EVTONLY)
        guard fd >= 0 else {
            return false
        }

        self.fd = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .link],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.onChange()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 {
                Darwin.close(fd)
                self?.fd = -1
            }
        }

        self.source = source
        source.resume()

        return true
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}
