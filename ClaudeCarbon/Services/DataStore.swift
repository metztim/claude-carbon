import Foundation
import SQLite3
import Combine

/// SQLite destructor type that tells SQLite to copy the string
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

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

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database at \(dbPath)")
        }
    }

    private func createTables() {
        // Sessions table
        let createSessionsTable = """
            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL UNIQUE,
                project_path TEXT,
                start_time REAL NOT NULL,
                last_activity_time REAL NOT NULL,
                input_tokens INTEGER NOT NULL DEFAULT 0,
                estimated_output_tokens INTEGER NOT NULL DEFAULT 0,
                model_name TEXT NOT NULL DEFAULT 'sonnet'
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

        executeSQL(createSessionsTable)
        executeSQL(createDailyTotalsTable)
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
                                input_tokens, estimated_output_tokens, model_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
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
        sqlite3_bind_int(statement, 7, Int32(session.estimatedOutputTokens))
        sqlite3_bind_text(statement, 8, session.modelName, -1, SQLITE_TRANSIENT)

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
                   input_tokens, estimated_output_tokens, model_name
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
            let estimatedOutputTokens = Int(sqlite3_column_int(statement, 6))
            let modelName = String(cString: sqlite3_column_text(statement, 7))

            session = Session(
                id: UUID(uuidString: idString) ?? UUID(),
                sessionId: sessionId,
                projectPath: projectPath,
                startTime: startTime,
                lastActivityTime: lastActivityTime,
                inputTokens: inputTokens,
                estimatedOutputTokens: estimatedOutputTokens,
                modelName: modelName
            )
        }

        sqlite3_finalize(statement)
        return session
    }

    func updateSession(_ session: Session) {
        let sql = """
            UPDATE sessions
            SET last_activity_time = ?, input_tokens = ?, estimated_output_tokens = ?
            WHERE session_id = ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing updateSession")
            return
        }

        sqlite3_bind_double(statement, 1, session.lastActivityTime.timeIntervalSince1970)
        sqlite3_bind_int(statement, 2, Int32(session.inputTokens))
        sqlite3_bind_int(statement, 3, Int32(session.estimatedOutputTokens))
        sqlite3_bind_text(statement, 4, session.sessionId, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error updating session: \(errorMessage)")
        }

        sqlite3_finalize(statement)
        refreshTodayStats()
    }

    // MARK: - Statistics

    func getTodayStats() -> (tokens: Int, energyWh: Double, carbonG: Double) {
        return getStatsForPeriod(days: 0)
    }

    func getWeekStats() -> (tokens: Int, energyWh: Double, carbonG: Double) {
        return getStatsForPeriod(days: 7)
    }

    func getAllTimeStats() -> (tokens: Int, energyWh: Double, carbonG: Double) {
        let sql = """
            SELECT
                COALESCE(SUM(input_tokens + estimated_output_tokens), 0) as total_tokens,
                COALESCE(SUM(input_tokens + estimated_output_tokens), 0) as total_tokens_for_energy
            FROM sessions
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return (0, 0.0, 0.0)
        }

        var tokens = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            tokens = Int(sqlite3_column_int(statement, 0))
        }

        sqlite3_finalize(statement)

        // Calculate energy using methodology (simplified - you'll want to use actual Methodology)
        let methodology = Methodology.default
        let avgJoulesPerToken = methodology.joulesPerToken["sonnet"] ?? 0.42
        let energyJ = Double(tokens) * avgJoulesPerToken * methodology.pue
        let energyWh = energyJ / 3600.0
        let carbonG = energyWh * methodology.carbonIntensity / 1000.0

        return (tokens, energyWh, carbonG)
    }

    private func getStatsForPeriod(days: Int) -> (tokens: Int, energyWh: Double, carbonG: Double) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startDate: Date

        if days == 0 {
            startDate = startOfToday
        } else {
            startDate = calendar.date(byAdding: .day, value: -days, to: startOfToday) ?? startOfToday
        }

        let sql = """
            SELECT
                COALESCE(SUM(input_tokens + estimated_output_tokens), 0) as total_tokens
            FROM sessions
            WHERE start_time >= ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return (0, 0.0, 0.0)
        }

        sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)

        var tokens = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            tokens = Int(sqlite3_column_int(statement, 0))
        }

        sqlite3_finalize(statement)

        // Calculate energy using methodology
        let methodology = Methodology.default
        let avgJoulesPerToken = methodology.joulesPerToken["sonnet"] ?? 0.42
        let energyJ = Double(tokens) * avgJoulesPerToken * methodology.pue
        let energyWh = energyJ / 3600.0
        let carbonG = energyWh * methodology.carbonIntensity / 1000.0

        return (tokens, energyWh, carbonG)
    }

    private func refreshTodayStats() {
        let stats = getTodayStats()
        DispatchQueue.main.async {
            self.todayTokens = stats.tokens
            self.todayEnergyWh = stats.energyWh
            self.todayCarbonG = stats.carbonG
        }
    }
}
