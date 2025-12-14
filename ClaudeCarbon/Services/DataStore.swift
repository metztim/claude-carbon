import Foundation
import SQLite3
import Combine

/// SQLite destructor type that tells SQLite to copy the string
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Statistics with per-model breakdown
struct UsageStats {
    let tokens: Int
    let energyWh: Double
    let carbonG: Double
    let tokensByModel: [String: Int] // "opus" -> 1000, "sonnet" -> 500, etc.
}

/// Daily usage data for charts
struct DailyUsage {
    let date: Date
    let tokens: Int
    let energyWh: Double
    let activeSeconds: Int  // Sum of session durations for burn rate
}

/// Hourly usage data for "Today" chart
struct HourlyUsage: Identifiable {
    let id = UUID()
    let hour: Int  // 0-23
    let date: Date  // Full date with hour set
    let tokens: Int
    let energyWh: Double
}

/// Burn rate data point (tokens per active hour)
struct BurnRatePoint {
    let date: Date
    let tokensPerActiveHour: Double
}

/// SQLite-backed data store for Claude Carbon sessions and statistics
class DataStore: ObservableObject {
    @Published var todayTokens: Int = 0
    @Published var todayEnergyWh: Double = 0.0
    @Published var todayCarbonG: Double = 0.0

    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        // Set up database path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = appSupport.appendingPathComponent("ClaudeCarbon", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        self.dbPath = appDir.appendingPathComponent("data.sqlite").path

        // Open database and create tables
        openDatabase()
        createTables()

        // Load initial stats
        refreshTodayStats()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Model Parsing

    /// Extract simplified model name from full model ID
    /// e.g., "claude-opus-4-5-20250514" -> "opus"
    ///       "claude-sonnet-4-20250514" -> "sonnet"
    ///       "claude-3-5-haiku-20241022" -> "haiku"
    static func parseModelName(_ fullModelId: String?) -> String {
        guard let modelId = fullModelId?.lowercased() else { return "sonnet" }

        if modelId.contains("opus") {
            return "opus"
        } else if modelId.contains("haiku") {
            return "haiku"
        } else if modelId.contains("sonnet") {
            return "sonnet"
        } else {
            return "sonnet" // default fallback
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        // Use FULLMUTEX for thread-safe access from multiple queues
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(dbPath, &db, flags, nil) != SQLITE_OK {
            print("Error opening database at \(dbPath)")
        }
    }

    private func createTables() {
        // Sessions table with updated schema
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL UNIQUE,
                project_path TEXT,
                start_time REAL NOT NULL,
                last_activity_time REAL NOT NULL,
                input_tokens INTEGER NOT NULL DEFAULT 0,
                output_tokens INTEGER NOT NULL DEFAULT 0,
                model_name TEXT NOT NULL DEFAULT 'sonnet',
                actual_model TEXT
            )
            """

        // Daily totals table
        let createDailyTotalsTable = """
            CREATE TABLE IF NOT EXISTS daily_totals (
                date TEXT PRIMARY KEY,
                input_tokens INTEGER NOT NULL DEFAULT 0,
                output_tokens INTEGER NOT NULL DEFAULT 0,
                energy_wh REAL NOT NULL DEFAULT 0.0,
                carbon_g REAL NOT NULL DEFAULT 0.0
            )
            """

        // JSONL file offsets table - tracks processing state per file
        let createOffsetsTable = """
            CREATE TABLE IF NOT EXISTS jsonl_offsets (
                file_path TEXT PRIMARY KEY,
                last_offset INTEGER NOT NULL DEFAULT 0
            )
            """

        executeSQL(createSessionsTable)
        executeSQL(createDailyTotalsTable)
        executeSQL(createOffsetsTable)

        // Run migrations for existing databases
        migrateSchema()
    }

    private func migrateSchema() {
        // Check if we need to migrate from estimated_output_tokens to output_tokens
        let checkColumnSQL = "PRAGMA table_info(sessions)"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, checkColumnSQL, -1, &statement, nil) == SQLITE_OK else {
            return
        }

        var hasEstimatedColumn = false
        var hasActualModel = false

        while sqlite3_step(statement) == SQLITE_ROW {
            if let namePtr = sqlite3_column_text(statement, 1) {
                let columnName = String(cString: namePtr)
                if columnName == "estimated_output_tokens" {
                    hasEstimatedColumn = true
                }
                if columnName == "actual_model" {
                    hasActualModel = true
                }
            }
        }
        sqlite3_finalize(statement)

        // Migrate estimated_output_tokens to output_tokens
        if hasEstimatedColumn {
            print("DataStore: Migrating estimated_output_tokens to output_tokens")
            executeSQL("ALTER TABLE sessions RENAME COLUMN estimated_output_tokens TO output_tokens")
        }

        // Add actual_model column if missing
        if !hasActualModel {
            print("DataStore: Adding actual_model column")
            executeSQL("ALTER TABLE sessions ADD COLUMN actual_model TEXT")
        }
    }

    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error executing SQL: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing SQL: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Session Management

    func saveSession(_ session: Session) {
        let sql = """
            INSERT INTO sessions (id, session_id, project_path, start_time, last_activity_time,
                                input_tokens, output_tokens, model_name, actual_model)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing saveSession")
            return
        }

        sqlite3_bind_text(statement, 1, session.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, session.sessionId, -1, SQLITE_TRANSIENT)

        if let projectPath = session.projectPath {
            sqlite3_bind_text(statement, 3, projectPath, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 3)
        }

        sqlite3_bind_double(statement, 4, session.startTime.timeIntervalSince1970)
        sqlite3_bind_double(statement, 5, session.lastActivityTime.timeIntervalSince1970)
        sqlite3_bind_int(statement, 6, Int32(session.inputTokens))
        sqlite3_bind_int(statement, 7, Int32(session.outputTokens))
        sqlite3_bind_text(statement, 8, session.modelName, -1, SQLITE_TRANSIENT)

        if let actualModel = session.actualModel {
            sqlite3_bind_text(statement, 9, actualModel, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 9)
        }

        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error saving session: \(errorMessage)")
        }

        sqlite3_finalize(statement)
        refreshTodayStats()
    }

    func getSession(byClaudeSessionId sessionId: String) -> Session? {
        let sql = """
            SELECT id, session_id, project_path, start_time, last_activity_time,
                   input_tokens, output_tokens, model_name, actual_model
            FROM sessions WHERE session_id = ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }

        sqlite3_bind_text(statement, 1, sessionId, -1, SQLITE_TRANSIENT)

        var session: Session?
        if sqlite3_step(statement) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(statement, 0))
            let sessionId = String(cString: sqlite3_column_text(statement, 1))

            let projectPath: String?
            if let pathPtr = sqlite3_column_text(statement, 2) {
                projectPath = String(cString: pathPtr)
            } else {
                projectPath = nil
            }

            let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            let lastActivityTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            let inputTokens = Int(sqlite3_column_int(statement, 5))
            let outputTokens = Int(sqlite3_column_int(statement, 6))
            let modelName = String(cString: sqlite3_column_text(statement, 7))

            let actualModel: String?
            if let modelPtr = sqlite3_column_text(statement, 8) {
                actualModel = String(cString: modelPtr)
            } else {
                actualModel = nil
            }

            session = Session(
                id: UUID(uuidString: idString) ?? UUID(),
                sessionId: sessionId,
                projectPath: projectPath,
                startTime: startTime,
                lastActivityTime: lastActivityTime,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                modelName: modelName,
                actualModel: actualModel
            )
        }

        sqlite3_finalize(statement)
        return session
    }

    func updateSession(_ session: Session) {
        let sql = """
            UPDATE sessions
            SET start_time = ?, last_activity_time = ?, input_tokens = ?, output_tokens = ?, actual_model = ?
            WHERE session_id = ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing updateSession")
            return
        }

        sqlite3_bind_double(statement, 1, session.startTime.timeIntervalSince1970)
        sqlite3_bind_double(statement, 2, session.lastActivityTime.timeIntervalSince1970)
        sqlite3_bind_int(statement, 3, Int32(session.inputTokens))
        sqlite3_bind_int(statement, 4, Int32(session.outputTokens))

        if let actualModel = session.actualModel {
            sqlite3_bind_text(statement, 5, actualModel, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        sqlite3_bind_text(statement, 6, session.sessionId, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error updating session: \(errorMessage)")
        }

        sqlite3_finalize(statement)
        refreshTodayStats()
    }

    /// Add actual tokens from JSONL monitoring to a session
    func addActualTokens(sessionId: String, inputTokens: Int, outputTokens: Int, model: String, timestamp: Date) {
        // First try to get existing session
        if var session = getSession(byClaudeSessionId: sessionId) {
            // Accumulate tokens
            session.inputTokens += inputTokens
            session.outputTokens += outputTokens
            session.actualModel = model
            session.lastActivityTime = timestamp
            // Update startTime if this entry is older (historical data)
            if timestamp < session.startTime {
                session.startTime = timestamp
            }
            updateSession(session)
            print("DataStore: Added actual tokens to session \(sessionId) - Input: \(inputTokens), Output: \(outputTokens)")
        } else {
            // Create new session with actual tokens using JSONL timestamp
            let newSession = Session(
                sessionId: sessionId,
                projectPath: nil,
                startTime: timestamp,
                lastActivityTime: timestamp,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                modelName: "sonnet",
                actualModel: model
            )
            saveSession(newSession)
            print("DataStore: Created session \(sessionId) with actual tokens - Input: \(inputTokens), Output: \(outputTokens)")
        }
    }

    // MARK: - JSONL Offset Tracking

    /// Get stored offset for a JSONL file (returns 0 if not found)
    func getOffset(forFile path: String) -> UInt64 {
        let sql = "SELECT last_offset FROM jsonl_offsets WHERE file_path = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }

        sqlite3_bind_text(statement, 1, path, -1, SQLITE_TRANSIENT)

        var offset: UInt64 = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            offset = UInt64(sqlite3_column_int64(statement, 0))
        }

        sqlite3_finalize(statement)
        return offset
    }

    /// Store offset for a JSONL file (upsert)
    func setOffset(forFile path: String, offset: UInt64) {
        let sql = """
            INSERT INTO jsonl_offsets (file_path, last_offset)
            VALUES (?, ?)
            ON CONFLICT(file_path) DO UPDATE SET last_offset = excluded.last_offset
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing setOffset")
            return
        }

        sqlite3_bind_text(statement, 1, path, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(statement, 2, Int64(offset))

        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error setting offset: \(errorMessage)")
        }

        sqlite3_finalize(statement)
    }

    /// Get all file paths stored in jsonl_offsets table
    func getAllOffsetPaths() -> [String] {
        let sql = "SELECT file_path FROM jsonl_offsets"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        var paths: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let pathPtr = sqlite3_column_text(statement, 0) {
                paths.append(String(cString: pathPtr))
            }
        }

        sqlite3_finalize(statement)
        return paths
    }

    /// Delete offset entry for a specific file
    func deleteOffset(forFile path: String) {
        let sql = "DELETE FROM jsonl_offsets WHERE file_path = ?"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing deleteOffset")
            return
        }

        sqlite3_bind_text(statement, 1, path, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error deleting offset: \(errorMessage)")
        }

        sqlite3_finalize(statement)
    }

    // MARK: - Statistics

    func getTodayStats() -> UsageStats {
        return getStatsForPeriod(days: 0)
    }

    func getWeekStats() -> UsageStats {
        return getStatsForPeriod(days: 7)
    }

    func getAllTimeStats() -> UsageStats {
        return getStatsForPeriod(days: nil)
    }

    private func getStatsForPeriod(days: Int?) -> UsageStats {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Build SQL - group by model
        // Use last_activity_time so sessions that continue across days are included
        let sql: String
        let hasDateFilter: Bool

        if days != nil {
            hasDateFilter = true
            sql = """
                SELECT
                    actual_model,
                    COALESCE(SUM(input_tokens + output_tokens), 0) as total_tokens
                FROM sessions
                WHERE last_activity_time >= ?
                GROUP BY actual_model
                """
        } else {
            hasDateFilter = false
            sql = """
                SELECT
                    actual_model,
                    COALESCE(SUM(input_tokens + output_tokens), 0) as total_tokens
                FROM sessions
                GROUP BY actual_model
                """
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return UsageStats(tokens: 0, energyWh: 0.0, carbonG: 0.0, tokensByModel: [:])
        }

        if hasDateFilter {
            let startDate: Date
            if days == 0 {
                startDate = startOfToday
            } else {
                startDate = calendar.date(byAdding: .day, value: -(days ?? 0), to: startOfToday) ?? startOfToday
            }
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
        }

        // Collect tokens per model
        var tokensByModel: [String: Int] = [:]
        var totalTokens = 0

        while sqlite3_step(statement) == SQLITE_ROW {
            let actualModel: String?
            if let cString = sqlite3_column_text(statement, 0) {
                actualModel = String(cString: cString)
            } else {
                actualModel = nil
            }
            let tokens = Int(sqlite3_column_int(statement, 1))

            let modelName = DataStore.parseModelName(actualModel)
            tokensByModel[modelName, default: 0] += tokens
            totalTokens += tokens
        }

        sqlite3_finalize(statement)

        // Calculate energy per model using model-specific J/token
        let methodology = Methodology.default
        var totalEnergyWh = 0.0

        for (model, tokens) in tokensByModel {
            let joulesPerToken = methodology.joulesPerToken[model] ?? methodology.joulesPerToken["sonnet"] ?? 1.0
            let energyJ = Double(tokens) * joulesPerToken * methodology.pue
            totalEnergyWh += energyJ / 3600.0
        }

        let carbonG = totalEnergyWh * methodology.carbonIntensity / 1000.0

        return UsageStats(tokens: totalTokens, energyWh: totalEnergyWh, carbonG: carbonG, tokensByModel: tokensByModel)
    }

    private func refreshTodayStats() {
        let stats = getTodayStats()
        DispatchQueue.main.async {
            self.todayTokens = stats.tokens
            self.todayEnergyWh = stats.energyWh
            self.todayCarbonG = stats.carbonG
        }
    }

    // MARK: - Time Series Data for Charts

    /// Get daily usage data for charting
    /// - Parameter days: Number of days to fetch (nil for all time)
    /// - Returns: Array of DailyUsage sorted by date ascending
    func getDailyUsage(days: Int?) -> [DailyUsage] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Query to aggregate by day
        let sql: String
        let startDate: Date?

        if let days = days {
            // days == 0 means today only, days == 7 means last 7 days
            if days == 0 {
                startDate = startOfToday
            } else {
                startDate = calendar.date(byAdding: .day, value: -days, to: startOfToday)
            }
            sql = """
                SELECT
                    date(last_activity_time, 'unixepoch', 'localtime') as day,
                    actual_model,
                    COALESCE(SUM(input_tokens + output_tokens), 0) as total_tokens,
                    COALESCE(SUM(last_activity_time - start_time), 0) as total_seconds
                FROM sessions
                WHERE last_activity_time >= ?
                GROUP BY day, actual_model
                ORDER BY day ASC
                """
        } else {
            // nil means all time - no date filter
            startDate = nil
            sql = """
                SELECT
                    date(last_activity_time, 'unixepoch', 'localtime') as day,
                    actual_model,
                    COALESCE(SUM(input_tokens + output_tokens), 0) as total_tokens,
                    COALESCE(SUM(last_activity_time - start_time), 0) as total_seconds
                FROM sessions
                GROUP BY day, actual_model
                ORDER BY day ASC
                """
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        if let startDate = startDate {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
        }

        // Collect data grouped by day, then aggregate across models
        var dayData: [String: (tokens: Int, energyWh: Double, activeSeconds: Int)] = [:]
        let methodology = Methodology.default

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let dayPtr = sqlite3_column_text(statement, 0) else { continue }
            let dayString = String(cString: dayPtr)

            let actualModel: String?
            if let cString = sqlite3_column_text(statement, 1) {
                actualModel = String(cString: cString)
            } else {
                actualModel = nil
            }

            let tokens = Int(sqlite3_column_int(statement, 2))
            let seconds = Int(sqlite3_column_int(statement, 3))

            // Calculate energy for this model's tokens
            let modelName = DataStore.parseModelName(actualModel)
            let joulesPerToken = methodology.joulesPerToken[modelName] ?? methodology.joulesPerToken["sonnet"] ?? 1.0
            let energyJ = Double(tokens) * joulesPerToken * methodology.pue
            let energyWh = energyJ / 3600.0

            // Aggregate into day
            var existing = dayData[dayString] ?? (tokens: 0, energyWh: 0.0, activeSeconds: 0)
            existing.tokens += tokens
            existing.energyWh += energyWh
            existing.activeSeconds += seconds
            dayData[dayString] = existing
        }

        sqlite3_finalize(statement)

        // Convert to DailyUsage array
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dayData.compactMap { (dayString, data) -> DailyUsage? in
            guard let date = dateFormatter.date(from: dayString) else { return nil }
            return DailyUsage(
                date: date,
                tokens: data.tokens,
                energyWh: data.energyWh,
                activeSeconds: data.activeSeconds
            )
        }.sorted { $0.date < $1.date }
    }

    /// Get burn rate (tokens per active hour) by day
    /// - Parameter days: Number of days to fetch (nil for all time)
    /// - Returns: Array of BurnRatePoint sorted by date ascending
    func getBurnRateByDay(days: Int?) -> [BurnRatePoint] {
        let dailyUsage = getDailyUsage(days: days)

        return dailyUsage.compactMap { usage -> BurnRatePoint? in
            // Filter out days with very short sessions (< 60 seconds total)
            guard usage.activeSeconds >= 60 else { return nil }

            let activeHours = Double(usage.activeSeconds) / 3600.0
            let tokensPerHour = Double(usage.tokens) / activeHours

            return BurnRatePoint(
                date: usage.date,
                tokensPerActiveHour: tokensPerHour
            )
        }
    }

    /// Get hourly usage for today (for hourly breakdown chart)
    /// - Returns: Array of HourlyUsage for each hour of today (0-23), sorted by hour
    func getTodayHourlyUsage() -> [HourlyUsage] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Query to aggregate by hour for today
        let sql = """
            SELECT
                strftime('%H', last_activity_time, 'unixepoch', 'localtime') as hour,
                actual_model,
                COALESCE(SUM(input_tokens + output_tokens), 0) as total_tokens
            FROM sessions
            WHERE last_activity_time >= ?
            GROUP BY hour, actual_model
            ORDER BY hour ASC
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }

        sqlite3_bind_double(statement, 1, startOfToday.timeIntervalSince1970)

        // Collect data grouped by hour
        var hourData: [Int: (tokens: Int, energyWh: Double)] = [:]
        let methodology = Methodology.default

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let hourPtr = sqlite3_column_text(statement, 0) else { continue }
            let hourString = String(cString: hourPtr)
            guard let hour = Int(hourString) else { continue }

            let actualModel: String?
            if let cString = sqlite3_column_text(statement, 1) {
                actualModel = String(cString: cString)
            } else {
                actualModel = nil
            }

            let tokens = Int(sqlite3_column_int(statement, 2))

            // Calculate energy for this model's tokens
            let modelName = DataStore.parseModelName(actualModel)
            let joulesPerToken = methodology.joulesPerToken[modelName] ?? methodology.joulesPerToken["sonnet"] ?? 1.0
            let energyJ = Double(tokens) * joulesPerToken * methodology.pue
            let energyWh = energyJ / 3600.0

            // Aggregate into hour
            var existing = hourData[hour] ?? (tokens: 0, energyWh: 0.0)
            existing.tokens += tokens
            existing.energyWh += energyWh
            hourData[hour] = existing
        }

        sqlite3_finalize(statement)

        // Convert to HourlyUsage array - include all hours with data
        return hourData.map { (hour, data) -> HourlyUsage in
            // Create a date for this hour
            let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfToday) ?? startOfToday
            return HourlyUsage(
                hour: hour,
                date: hourDate,
                tokens: data.tokens,
                energyWh: data.energyWh
            )
        }.sorted { $0.hour < $1.hour }
    }
}
