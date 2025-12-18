# Claude Carbon Session Log

---

## Session Log: 2025-12-10

**Project**: ai-watchdog/claude-carbon
**Duration**: ~60 minutes
**Type**: [bugfix] [feature]

### Objectives
- Debug why tokens show as 0 in ClaudeCarbon UI despite console showing activity
- Improve token tracking accuracy

### Summary
Fixed three critical bugs preventing token display: (1) SQLite string binding using `nil` instead of `SQLITE_TRANSIENT`, causing data corruption; (2) `NSHomeDirectory()` returning sandbox container path instead of real home; (3) App sandboxing blocking file access. Also increased output multiplier from 2.5x to 4x. Discovered that accurate token counts are available in Claude Code's session JSONL files and created a detailed plan for implementing precise tracking in v2.

### Files Changed

**Bug Fixes:**
- `ClaudeCarbon/Services/DataStore.swift` - Added `SQLITE_TRANSIENT` constant, replaced all `sqlite3_bind_text(..., nil)` with `sqlite3_bind_text(..., SQLITE_TRANSIENT)` to fix string memory corruption
- `ClaudeCarbon/Services/HistoryMonitor.swift` - Changed from `NSHomeDirectory()` to `getpwuid(getuid()).pw_dir` to get real home directory outside sandbox
- `ClaudeCarbon/ClaudeCarbon.entitlements` - Added `com.apple.security.app-sandbox = false` to disable sandboxing
- `ClaudeCarbon/Resources/Methodology.json` - Increased `outputMultiplier` from 2.5 to 4.0

**Build Settings (via Xcode UI):**
- Disabled "Enable App Sandbox" in target Build Settings

### Technical Notes

1. **SQLite String Binding Bug**: Swift strings passed to `sqlite3_bind_text()` with `nil` destructor get deallocated before SQLite uses them. Fix: use `SQLITE_TRANSIENT` (defined as `unsafeBitCast(-1, to: sqlite3_destructor_type.self)`) which tells SQLite to copy the string immediately.

2. **Sandbox Home Directory Issue**: When app is sandboxed, `NSHomeDirectory()` returns `~/Library/Containers/com.app.name/Data/` instead of `/Users/username/`. Fix: use POSIX `getpwuid(getuid())` to get real home directory.

3. **Token Data Discovery**: Found that Claude Code logs actual API token usage in session JSONL files at:
   ```
   ~/.claude/projects/{encoded-project-path}/{session-id}.jsonl
   ```
   Each `type: "assistant"` entry contains `message.usage.input_tokens` and `message.usage.output_tokens`.

4. **Path Encoding**: Project paths are encoded with slashes replaced by dashes:
   `/Users/tim/Projects/foo` → `-Users-tim-Projects-foo`

### Future Plans & Unimplemented Phases

**Plan saved at**: `~/.claude/plans/buzzing-tumbling-trinket.md`

#### Phase: Accurate Token Tracking (v2)
**Status**: Planned, not started

**Goal**: Replace estimated tokens with actual token counts from session JSONL files.

**Implementation Steps**:

1. **Create SessionJSONLMonitor service** (`Services/SessionJSONLMonitor.swift`):
   - Watch `~/.claude/projects/` directory for JSONL files
   - Tail-read new lines (same pattern as HistoryMonitor)
   - Parse `type: "assistant"` entries to extract:
     - `sessionId`
     - `message.model`
     - `message.usage.input_tokens`
     - `message.usage.output_tokens`
   - Publish token updates via Combine `@Published var tokenUpdate: TokenUpdate?`

2. **Update Session Model** (`Models/Session.swift`):
   - Rename `estimatedOutputTokens` → `outputTokens`
   - Add `actualModel: String?` field

3. **Update DataStore Schema** (`Services/DataStore.swift`):
   - Migration: `ALTER TABLE sessions ADD COLUMN actual_model TEXT`
   - Migration: `ALTER TABLE sessions RENAME COLUMN estimated_output_tokens TO output_tokens`
   - Add method: `addActualTokens(sessionId:inputTokens:outputTokens:model:)`

4. **Update SessionCoordinator** (`Services/SessionCoordinator.swift`):
   - Subscribe to SessionJSONLMonitor in addition to HistoryMonitor
   - Accumulate actual tokens when received
   - Remove dependency on TokenEstimator

5. **Initialize in App** (`App/ClaudeCarbonApp.swift`):
   - Add `@StateObject private var sessionJSONLMonitor = SessionJSONLMonitor()`
   - Pass to SessionCoordinator

6. **Delete TokenEstimator** (`Services/TokenEstimator.swift`):
   - No longer needed once using actual tokens

**Design Decisions**:
- No estimation fallback - only track sessions with actual token data
- Sum all `usage` entries per response (multiple API calls per prompt)
- Works for both API and subscription users (Claude Code logs tokens regardless)

### Next Actions
- [ ] Commit current bug fixes (SQLite, sandbox, home directory, multiplier)
- [ ] Execute v2 plan in new session using prompt:
  ```
  Execute the plan at ~/.claude/plans/buzzing-tumbling-trinket.md
  Project: /Users/timmetz/Developer/Projects/Personal/ai-watchdog/claude-carbon
  ```
- [ ] Test accurate token tracking after v2 implementation
- [ ] Add app icon images to Assets.xcassets

### Metrics
- Files modified: 4
- Build settings changed: 1 (sandbox disabled)
- Plans created: 1 (`buzzing-tumbling-trinket.md`)

---

## Session Log: 2025-12-10 (Session 2)

**Project**: ai-watchdog/claude-carbon
**Duration**: ~20 minutes
**Type**: [feature] [refactor]

### Objectives
- Execute plan at `~/.claude/plans/buzzing-tumbling-trinket.md`
- Replace estimated token tracking with actual token counts from Claude Code's session JSONL files

### Summary
Implemented accurate token tracking by reading actual `input_tokens` and `output_tokens` from Claude Code's session JSONL files at `~/.claude/projects/{path}/{session}.jsonl`. Created new `SessionJSONLMonitor` service, updated data models and database schema, refactored `SessionCoordinator` to use actual tokens instead of estimates, and removed the now-obsolete `TokenEstimator`.

### Files Changed

**New File:**
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Monitors `~/.claude/projects/` for JSONL files, parses `type: "assistant"` entries, extracts actual token usage and model info, publishes updates via Combine

**Modified Files:**
- `ClaudeCarbon/Models/Session.swift` - Renamed `estimatedOutputTokens` → `outputTokens`, added `actualModel: String?` field
- `ClaudeCarbon/Services/DataStore.swift` - Added schema migration (rename column, add `actual_model`), added `addActualTokens()` method, updated all SQL queries
- `ClaudeCarbon/Services/SessionCoordinator.swift` - Removed TokenEstimator dependency, now subscribes to SessionJSONLMonitor for actual tokens
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Added `@StateObject` for `SessionJSONLMonitor`, passes to `SessionCoordinator`
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Removed TokenEstimator.swift, added SessionJSONLMonitor.swift

**Deleted File:**
- `ClaudeCarbon/Services/TokenEstimator.swift` - No longer needed with actual token tracking

### Technical Notes

1. **JSONL File Location**: Claude Code logs API responses to:
   ```
   ~/.claude/projects/{encoded-path}/{sessionId}.jsonl
   ```
   Path encoding: `/Users/tim/foo` → `-Users-tim-foo`

2. **Token Extraction**: Each API response logged as `type: "assistant"` with:
   ```json
   {
     "message": {
       "model": "claude-opus-4-5-20251101",
       "usage": { "input_tokens": 10, "output_tokens": 198 }
     }
   }
   ```

3. **File Monitoring Pattern**: `SessionJSONLMonitor` uses same dispatch source pattern as `HistoryMonitor`:
   - Directory watcher for new project folders
   - Individual file watchers per JSONL file
   - Tail-reading with offset tracking

4. **Schema Migration**: DataStore now auto-migrates old databases:
   - Renames `estimated_output_tokens` → `output_tokens`
   - Adds `actual_model` column
   - Uses `PRAGMA table_info` to check existing schema

5. **Architecture Change**: Token flow is now:
   - `HistoryMonitor` → Creates session records (from history.jsonl)
   - `SessionJSONLMonitor` → Adds actual tokens (from project JSONL files)
   - `SessionCoordinator` → Coordinates both into `DataStore`

### Future Plans & Unimplemented Phases

**Core implementation complete. Remaining from plan:**

#### Future Enhancement: Cache Token Accounting (Not started)
- Account for `cache_creation_input_tokens` and `cache_read_input_tokens`
- Cache reads are effectively "free" compute

#### Future Enhancement: Per-Model Energy Coefficients (Not started)
- Use `actual_model` to apply model-specific J/token values
- Different coefficients for Opus vs Sonnet vs Haiku

#### Future Enhancement: Historical Backfill (Not started)
- Option to read existing JSONL files on first launch
- Populate historical token usage

### Next Actions
- [ ] Build and test in Xcode to verify token tracking works
- [ ] Verify tokens accumulate correctly across multiple prompts
- [ ] Test schema migration with existing database
- [ ] Add app icon images to Assets.xcassets
- [ ] Commit all changes

### Metrics
- Files modified: 5
- Files created: 1
- Files deleted: 1
- Lines of code: ~280 new (SessionJSONLMonitor), ~60 modified (others)

---
