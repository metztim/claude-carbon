# Claude Carbon Session Log

---

## Session Log: 2025-12-08

**Project**: ai-watchdog/claude-carbon
**Duration**: ~45 minutes
**Type**: [feature]

### Objectives
- Build Claude Carbon - a macOS menu bar app that monitors Claude Code energy consumption
- Implement full MVP following plan in `~/.claude/plans/squishy-brewing-lighthouse.md`

### Summary
Built complete Claude Carbon macOS menu bar app from scratch. Created Xcode project structure, implemented all models (Session, EnergyEstimate, Methodology), services (DataStore, HistoryMonitor, TokenEstimator, EnergyCalculator), and SwiftUI views (MenuBarView, StatsView, SessionRow, ComparisonView, SettingsView). Fixed compilation errors and refactored to use SwiftUI's native `MenuBarExtra` for proper menu bar integration.

### Files Changed

**Project Configuration:**
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Xcode project configuration for macOS 13+ app
- `ClaudeCarbon/Info.plist` - App info with URL scheme (claudecarbon://) and LSUIElement
- `ClaudeCarbon/ClaudeCarbon.entitlements` - Sandbox disabled for file access

**App Layer:**
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Main entry with MenuBarExtra for menu bar icon
- `ClaudeCarbon/App/AppDelegate.swift` - URL scheme handler registration
- `ClaudeCarbon/App/URLSchemeHandler.swift` - Handles claudecarbon:// events

**Models:**
- `ClaudeCarbon/Models/Session.swift` - Session data model with tokens, timestamps
- `ClaudeCarbon/Models/EnergyEstimate.swift` - Energy calculation results with household comparisons
- `ClaudeCarbon/Models/Methodology.swift` - Configurable energy coefficients (J/token, PUE, carbon intensity)

**Services:**
- `ClaudeCarbon/Services/DataStore.swift` - SQLite persistence (raw SQLite3 API, no dependencies)
- `ClaudeCarbon/Services/HistoryMonitor.swift` - File watcher for ~/.claude/history.jsonl
- `ClaudeCarbon/Services/TokenEstimator.swift` - Character-based token estimation (4 chars ≈ 1 token)
- `ClaudeCarbon/Services/EnergyCalculator.swift` - Energy/carbon calculations from tokens

**Views:**
- `ClaudeCarbon/Views/MenuBarView.swift` - Main popover UI (360x480)
- `ClaudeCarbon/Views/StatsView.swift` - Token/energy/carbon statistics display
- `ClaudeCarbon/Views/SessionRow.swift` - Individual session display
- `ClaudeCarbon/Views/ComparisonView.swift` - Household energy comparisons
- `ClaudeCarbon/Views/SettingsView.swift` - Methodology configuration panel

**Resources:**
- `ClaudeCarbon/Resources/Assets.xcassets/` - App icon, accent color, menu bar icon
- `ClaudeCarbon/Resources/Methodology.json` - Default energy coefficients with sources

**Scripts:**
- `Scripts/install-hooks.sh` - Installs Claude Code hooks for event capture
- `Scripts/uninstall-hooks.sh` - Removes hooks cleanly

**Documentation:**
- `README.md` - Installation and usage guide
- `METHODOLOGY.md` - Transparent energy estimation methodology

### Technical Notes

1. **MenuBarExtra vs NSStatusItem**: Initially used AppDelegate with NSStatusItem/NSPopover pattern, but menu bar icon wasn't appearing. Refactored to use SwiftUI's native `MenuBarExtra` (macOS 13+) which handles lifecycle properly.

2. **SQLite without dependencies**: Used raw SQLite3 C API (`import SQLite3`) to avoid external package dependencies. Database stored at `~/Library/Application Support/ClaudeCarbon/data.sqlite`.

3. **Token estimation approach**: Simple character-based (4 chars ≈ 1 token) with 2.5x output multiplier. Avoids heavy tokenizer dependencies for MVP.

4. **Energy formulas**:
   - Energy (Wh) = tokens × J/token × PUE / 3600
   - Carbon (gCO2e) = energyWh × carbonIntensity / 1000

5. **Build errors fixed**:
   - HistoryMonitor init takes no arguments (starts monitoring in init)
   - Removed explicit startMonitoring() call
   - Fixed optional unwrapping for historyMonitor in MenuBarView

### Future Plans & Unimplemented Phases

**All MVP phases were completed. Future v2 features from plan:**

#### Phase v2: Precision Mode (Not started)
**Planned Steps**:
1. Implement optional HTTPS proxy to intercept Claude API calls
2. Parse actual token counts from API responses (`usage.input_tokens`, `usage.output_tokens`)
3. Add toggle in settings to enable/disable proxy mode
4. Store precise vs estimated flag per session

#### Phase v2: Model Recommendations (Not started)
**Planned Steps**:
1. Analyze prompt complexity to suggest appropriate model
2. Add "This could use Haiku" suggestions when Opus/Sonnet used for simple queries
3. Calculate potential energy savings from model downgrades

#### Phase v2: Multi-tool Support (Not started)
**Planned Steps**:
1. Add ChatGPT tracking (different history file locations)
2. Add Copilot tracking
3. Unified dashboard across all AI tools

### Next Actions
- [ ] Test app in Xcode - verify menu bar icon appears after MenuBarExtra refactor
- [ ] Test hook installation script on clean system
- [ ] Verify history.jsonl parsing works with real Claude Code usage
- [ ] Add app icon images to Assets.xcassets (currently empty placeholders)
- [ ] Consider code signing for distribution

### Metrics
- Files created: 25
- Lines of Swift code: ~1,500
- External dependencies: 0 (pure Swift/Foundation/SwiftUI)

---

## Session Log: 2025-12-09

**Project**: ai-watchdog/claude-carbon
**Duration**: ~15 minutes
**Type**: [bugfix]

### Objectives
- Debug why Claude Carbon shows active sessions but 0 tokens

### Summary
Identified and fixed critical bug: the app had three disconnected components (HistoryMonitor, TokenEstimator, DataStore) with no coordinator connecting them. Created `SessionCoordinator` service that listens to prompt notifications, estimates tokens, and updates session records in the database.

### Files Changed
- `ClaudeCarbon/Services/SessionCoordinator.swift` - NEW: Bridges HistoryMonitor → TokenEstimator → DataStore using Combine publishers
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Added SessionCoordinator initialization on app launch
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Added SessionCoordinator.swift to build

### Technical Notes

1. **Root Cause**: `HistoryMonitor` correctly detected sessions and prompts, posting notifications and updating `currentSessionId`/`lastPromptText` published properties. However, nothing was:
   - Listening to those notifications
   - Calling `TokenEstimator` to estimate tokens from prompt text
   - Creating/updating Session records in `DataStore`

2. **Fix**: Created `SessionCoordinator` that:
   - Subscribes to `historyMonitor.$lastPromptText` via Combine
   - Calls `tokenEstimator.estimateTotalTokens(from: text)` for each prompt
   - Creates new Session or updates existing one in DataStore with accumulated tokens
   - Deduplicates prompts using `lastProcessedPrompt` check

3. **Initialization**: SessionCoordinator initialized lazily in `ClaudeCarbonApp.body.onAppear` to ensure StateObjects are ready first.

### Future Plans & Unimplemented Phases

**All bugfix work completed. Remaining from previous session:**

#### Phase v2: Precision Mode (Not started)
- HTTPS proxy to intercept actual API token counts
- Toggle in settings for proxy mode

#### Phase v2: Model Recommendations (Not started)
- Suggest Haiku for simple queries
- Show potential energy savings

#### Phase v2: Multi-tool Support (Not started)
- ChatGPT and Copilot tracking
- Unified dashboard

### Next Actions
- [ ] Rebuild app in Xcode and test token tracking
- [ ] Verify tokens accumulate across multiple prompts in same session
- [ ] Test stats refresh when switching time ranges (Today/Week/All Time)
- [ ] Add app icon images to Assets.xcassets

### Metrics
- Files modified: 2
- Files created: 1
- Lines added: ~95
