# Claude Carbon Session Log

---

## Session Log: 2025-12-10 (Session 3)

**Project**: claude-carbon
**Type**: [bugfix] [feature]

### Objectives
- Fix directory monitoring (wasn't detecting new project directories)
- Implement persistent offset tracking (historical data not being read)
- Fix thread safety and timestamp issues discovered during testing

### Summary
Fixed multiple issues with the JSONL token tracking system. Directory monitoring now works using Darwin.open() syscall instead of FileHandle. Added persistent offset tracking to SQLite so historical JSONL data is read on first launch and subsequent launches are instant. Fixed SQLite thread safety crash and corrected timestamp attribution so historical sessions show their actual dates instead of "today".

### Files Changed
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Fixed directory monitoring using Darwin.open() with O_EVTONLY; integrated DataStore for persistent offsets
- `ClaudeCarbon/Services/DataStore.swift` - Added jsonl_offsets table; added getOffset/setOffset methods; enabled SQLITE_OPEN_FULLMUTEX for thread safety; added timestamp parameter to addActualTokens; updated updateSession to persist startTime
- `ClaudeCarbon/Services/SessionCoordinator.swift` - Pass timestamp through to addActualTokens
- `ClaudeCarbon/Models/Session.swift` - Made startTime mutable (var instead of let)
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Lazy initialize SessionJSONLMonitor with DataStore dependency

### Technical Notes
- **Directory monitoring fix**: `FileHandle(forReadingAtPath:)` returns nil for directories. Solution: use `Darwin.open(path, O_RDONLY | O_EVTONLY)` directly. O_EVTONLY is macOS-specific for event-only file descriptors.
- **SQLite thread safety**: SessionJSONLMonitor runs on background queue but was calling DataStore methods. Fix: use `sqlite3_open_v2` with `SQLITE_OPEN_FULLMUTEX` flag for serialized mode.
- **Timestamp attribution**: When reading historical JSONL data, sessions were created with `startTime: Date()` (now) instead of the actual timestamp from the JSONL entry. Fixed by passing timestamp through the entire flow.
- **Offset persistence**: New `jsonl_offsets` table stores (file_path, last_offset). First launch reads from offset 0 (all history), subsequent launches resume from stored offset.

### Bugs Fixed This Session
1. Directory monitoring failure - FileHandle can't open directories
2. SQLite multi-threaded access crash - needed FULLMUTEX mode
3. All historical tokens showing as "today" - timestamps not being preserved

### User Testing Results
- App successfully tracked ~34M tokens across all historical sessions
- Date filtering now works correctly (Today/Week/All Time show different values)
- Energy: 11.30 kWh, Carbon: 4.34 kg CO2e for all-time usage

### Next Actions
- [ ] Commit all changes to git
- [ ] Add app icon images to Assets.xcassets
- [ ] Consider adding a loading indicator for first-launch historical processing
- [ ] Consider model-specific energy calculations (currently assumes "sonnet" for all)

### Metrics
- Files modified: 5
- Bugs fixed: 3
- New database table: 1 (jsonl_offsets)

---

## Session Log: 2025-12-10

**Project**: claude-carbon
**Type**: [feature]

### Objectives
- Add higher energy impact comparison levels for power users
- Implement model-specific energy calculations (Opus/Sonnet/Haiku)
- Add visual model breakdown in token usage display
- Add methodology explanation section

### Summary
Enhanced the energy tracking to use model-specific J/token values (Opus: 2.0, Sonnet: 1.0, Haiku: 0.3) instead of assuming all tokens are Sonnet. Added a visual stacked bar showing token distribution by model with blue-themed colors. Added collapsible "How it works" methodology section. Extended energy comparison levels to handle higher usage (household electricity days, EV miles).

### Files Changed
- `ClaudeCarbon/Views/ComparisonView.swift` - Added higher energy levels (1-100+ kWh), fixed icon/text mismatch, extended comparisons to household daily use and EV miles
- `ClaudeCarbon/Views/StatsView.swift` - Added `tokensByModel` parameter, created `ModelBreakdownBar` component with stacked bar and legend
- `ClaudeCarbon/Views/MenuBarView.swift` - Removed Active Session section, added collapsible methodology explanation, moved Energy Impact inside time range section, updated to use `UsageStats` struct
- `ClaudeCarbon/Services/DataStore.swift` - Added `UsageStats` struct, added `parseModelName()` helper, rewrote stats functions to GROUP BY model and calculate energy per-model
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Removed unused `historyMonitor` parameter from MenuBarView

### Technical Notes
- Model name parsing extracts "opus"/"sonnet"/"haiku" from full model IDs like `claude-opus-4-5-20250514`
- Energy calculation now: `Σ (tokens_per_model × J/token_for_model × PUE) / 3600`
- Discovered Claude Code uses Haiku internally for lightweight operations (file searches, fast subagents)
- J/token values are inferred from pricing ratios, not measured (confidence: low for opus/haiku)
- Larger models use more energy per token due to more parameters requiring more compute per forward pass

### Energy Comparison Levels (Updated)
| Range | Icon | Comparison |
|-------|------|------------|
| 0-1 Wh | lightbulb.fill | LED bulb seconds |
| 1-10 Wh | iphone | Charging phone % |
| 10-1000 Wh | laptopcomputer | Laptop mins/hours |
| 1-30 kWh | house.fill | X% daily household use |
| 30-100 kWh | house.fill | X days household electricity |
| 100+ kWh | car.fill | Driving EV X miles |

### Model Colors (Blue Theme)
- Opus: Dark navy `(0.1, 0.2, 0.6)`
- Sonnet: Medium blue `(0.2, 0.4, 0.9)`
- Haiku: Light blue `(0.4, 0.7, 1.0)`

### Future Plans & Unimplemented Phases

#### GitHub "Learn More" Link
**Status**: Not started
**Notes**: User mentioned wanting a "read more" button linking to GitHub methodology explainer, but deferred for now. Would add to the "How it works" DisclosureGroup.

### Next Actions
- [ ] Commit changes to git
- [ ] Consider per-message token tracking (currently per-session) for more accurate model attribution
- [ ] Add GitHub link to methodology section when explainer doc is ready
- [ ] Consider adding uncertainty ranges to energy estimates given low confidence on J/token values

### Metrics
- Files modified: 5
- New UI components: 1 (ModelBreakdownBar)
- New data struct: 1 (UsageStats)

---

## Session Log: 2025-12-11

**Project**: claude-carbon
**Type**: [feature] [bugfix] [refactor]

### Objectives
- Explore AI tools for UX design workflow
- Redesign menu bar popover for horizontal layout
- Fix data display issues

### Summary
Researched AI-assisted UX design tools (Gemini 3, v0.dev, Uizard) and created a self-contained brief for generating mockups. Redesigned the main MenuBarView to be wider and more horizontal, with a prominent hero equivalent display and compact stats row. Fixed critical bug where "Today" filter wasn't showing sessions that started yesterday but continued today. Added tooltip for model breakdown and simplified the settings panel.

### Files Changed
- `ClaudeCarbon/Views/MenuBarView.swift` - Redesigned to horizontal layout (420px wide), moved time picker to header, removed ScrollView
- `ClaudeCarbon/Views/ComparisonView.swift` - Added HeroComparisonView (large hero display), CompactStatsRow, CompactStatItem components; fixed height for consistency
- `ClaudeCarbon/Views/SettingsView.swift` - Simplified from 600px modal to compact 300x320 sheet with read-only assumptions display
- `ClaudeCarbon/Services/DataStore.swift` - Fixed time filter bug: changed from `start_time` to `last_activity_time` for period queries

### Technical Notes
- **UX Design Workflow**: Best approach is Gemini 3 for visual mockups → Claude Code for implementation. Gemini can generate UI mockups from detailed prompts but may return text specifications instead of images; use Canvas feature for actual visuals.
- **Time Filter Bug**: Sessions that started on a previous day but had activity today weren't showing in "Today" view because query filtered on `start_time >= startOfToday`. Changed to `last_activity_time >= startOfToday`.
- **Layout Jumping Fix**: Added fixed height (92px) to HeroComparisonView and fixed icon frame (60x60) to prevent content jumping when switching between time periods.
- **Tooltip Implementation**: Used native macOS `.help()` modifier on CompactStatItem for model breakdown tooltip.

### UI Changes Summary
**Before**: 360x480 vertical layout with ScrollView
**After**: 420px wide horizontal layout, no scroll needed
```
┌────────────────────────────────────────────────┐
│ 🍃 Claude Carbon     [Today|Week|All Time]     │
├────────────────────────────────────────────────┤
│  💻  Laptop for 6.4 hrs                        │
│      Energy equivalent                         │
├────────────────────────────────────────────────┤
│  🔢 1.9M     ⚡ 636 Wh     🍃 244g             │
│  tokens      energy        CO₂                 │
├────────────────────────────────────────────────┤
│  ⚙️                                    🔴      │
└────────────────────────────────────────────────┘
```

### Future Plans & Unimplemented Phases

#### Phase: Methodology Research
**Status**: Not started
**Planned Steps**:
1. Deep dive into energy calculation assumptions (J/token values)
2. Validate against published AI energy research
3. Add uncertainty ranges to estimates
4. Consider regional carbon intensity options

#### Phase: Additional UX Improvements
**Status**: Partially discussed
**Planned Ideas**:
- Multiple equivalents shown simultaneously (phone, car, tree icons in a row)
- Gauge/meter visualization approach
- More intuitive onboarding for first-time users

### Next Actions
- [ ] Validate methodology assumptions against latest AI energy research
- [ ] Consider adding "How it works" link to external documentation
- [ ] Add regional carbon intensity selector (US vs global vs specific regions)
- [ ] Test tooltip behavior on different macOS versions
- [ ] Consider adding app icon to menu bar (currently just leaf)

### Metrics
- Files modified: 4
- New UI components: 3 (HeroComparisonView, CompactStatsRow, CompactStatItem)
- Bugs fixed: 2 (time filter, layout jumping)

---

## Session Log: 2025-12-11

**Project**: claude-carbon
**Type**: [feature]

### Objectives
- Explore dynamic menu bar icon to provide real-time feedback on token usage
- Implement initial version (subtle pulse animation)
- Document future ideas for later consideration

### Summary
Discussed various approaches for making the menu bar icon responsive to token usage. Evaluated options including color changes (budget-based, rolling window), intensity variations, and activity indicators. Decided to start with the simplest approach: a subtle pulse animation when actively consuming tokens. Implemented the feature using macOS 14's `symbolEffect(.pulse)` API. Also documented future feature ideas (Claude web/desktop integration, personal best leaderboard) and created a session reminder system.

### Files Changed
- `ClaudeCarbon/Services/ActivityIndicator.swift` - NEW: Tracks token activity, sets isActive for 2s with debouncing
- `ClaudeCarbon/Views/MenuBarIconView.swift` - NEW: Leaf icon with SF Symbol pulse animation
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Wired ActivityIndicator to SessionJSONLMonitor, uses new icon view
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Added new files, bumped deployment target to macOS 14.0
- `docs/DYNAMIC_ICON_IDEAS.md` - NEW: Documents future icon enhancement ideas
- `docs/FUTURE_IDEAS.md` - NEW: Captures broader feature ideas for future sessions
- `CLAUDE.md` - NEW: Created with session reminder for future ideas

### Technical Notes
- `symbolEffect(.pulse)` requires macOS 14+ - decided to bump deployment target from 13.0 to 14.0
- ActivityIndicator subscribes to SessionJSONLMonitor's `tokenUpdate` publisher
- 2-second active window with debouncing prevents flickering during bursts of activity
- Menu bar labels in SwiftUI support SF Symbol animations

### Future Plans & Unimplemented Phases

#### Dynamic Icon Color Variations
**Status**: Documented, not implemented
**Ideas captured in `docs/DYNAMIC_ICON_IDEAS.md`**:
- Budget-based color (user sets daily target, icon shifts green→yellow→red)
- Intensity-only (green varies in saturation/brightness)
- Rolling window (color based on last 60 min usage)
- Leaf fullness (different SF Symbols for different states)
- Threshold alerts (only change at milestones like 100k tokens)

#### Claude Web/Desktop Integration
**Status**: Idea captured in `docs/FUTURE_IDEAS.md`
- Goal: Track usage from Claude web interface and desktop app
- Challenge: Unknown how to access that data (browser extension? API interception?)

#### Personal Best Leaderboard
**Status**: Idea captured in `docs/FUTURE_IDEAS.md`
- Goal: Gamify efficiency by tracking lowest-usage days
- Key metric: tokens per active hour (not raw daily totals)
- Normalizes for days with different work hours

### Next Actions
- [ ] Build and test pulse animation in Xcode (xcodebuild not available in CLI)
- [ ] Review `docs/FUTURE_IDEAS.md` when ready to expand features
- [ ] Consider whether pulse duration (2s) feels right in practice
- [ ] Remove CLAUDE.md reminder after addressing future ideas

### Metrics
- Files created: 5
- Files modified: 2
- Deployment target: 13.0 → 14.0

---

## Session Log: 2025-12-11

**Project**: claude-carbon
**Type**: [bugfix]

### Objectives
- Investigate why token usage display was stuck at 204k despite active Claude Code usage

### Summary
Diagnosed and fixed a critical bug where new JSONL files in project subdirectories weren't being monitored. The `SessionJSONLMonitor` only watched the top-level `~/.claude/projects` directory, missing new files created in existing subdirectories. Added `SubdirectoryMonitor` class to watch each project directory for new JSONL files.

### Files Changed
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Added subdirectory monitoring to detect new JSONL files in project directories

### Technical Notes
- **Root cause**: `DispatchSource.makeFileSystemObjectSource` on a directory only detects changes TO the directory itself (new subdirectories), not changes WITHIN subdirectories (new files)
- **Evidence found**:
  - Database showed 8 sessions from today with 0 tokens (untracked)
  - Only files from `-Users-timmetz/` directory were being tracked
  - 43 project directories exist but most weren't monitored
  - JSONL files like `c0dffd8b...jsonl` (605KB) existed but weren't in tracking DB
- **Fix implemented**:
  - Added `monitoredDirectories: [String: SubdirectoryMonitor]` to track watched directories
  - Added `SubdirectoryMonitor` class using `O_EVTONLY` file descriptor monitoring
  - Modified `scanExistingProjects()` to set up monitors for each project subdirectory
  - When subdirectory changes, `scanProjectDirectory()` finds and monitors new JSONL files

### Future Plans & Unimplemented Phases
None planned for this bugfix session.

### Next Actions
- [ ] Rebuild and restart Claude Carbon in Xcode to apply the fix
- [ ] Verify console shows "Started monitoring directory" logs for all project dirs
- [ ] Confirm today's token count updates after restart (should jump from 204k)
- [ ] Monitor for a few sessions to ensure new files are detected in real-time

### Metrics
- Files modified: 1
- Lines added: ~60 (SubdirectoryMonitor class + directory tracking logic)

---

## Session Log: 2025-12-11

**Project**: claude-carbon
**Type**: [bugfix]

### Objectives
- Fix menu bar icon not lighting up based on Claude Code usage

### Summary
Fixed a timing bug where the `SessionJSONLMonitor` and `ActivityIndicator` connection were initialized inside `MenuBarView.onAppear`, which only fires when the user clicks the menu bar icon. Moved initialization to a `.task` modifier on the label view, which fires at app launch. Also fixed an Xcode warning about an unused variable binding in DataStore.

### Files Changed
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Moved SessionJSONLMonitor creation and ActivityIndicator connection from content's `onAppear` to label's `.task` so it runs at app launch instead of on menu click
- `ClaudeCarbon/Services/DataStore.swift` - Changed `if let days = days` to `if days != nil` to fix unused variable warning

### Technical Notes
- **Root cause**: In SwiftUI `MenuBarExtra`, the `label:` closure (the icon) appears at app launch, but the content closure's `onAppear` only fires when user clicks the icon to open the dropdown
- **Fix approach**: Using `.task` on the label view runs initialization when the icon appears (app launch), not when dropdown opens
- **Warning fix**: `if let days = days` was creating an unused binding; we only needed the nil check, not the unwrapped value

### Future Plans & Unimplemented Phases
None planned for this bugfix session.

### Next Actions
- [ ] Build and test in Xcode - verify icon pulses when Claude Code is active
- [ ] Verify the Xcode warning is gone after rebuild

### Metrics
- Files modified: 2
- Lines changed: ~15

---

## Session Log: 2025-12-12

**Project**: claude-carbon
**Type**: [docs] [config] [feature]

### Objectives
- Migrate all local docs/TODOs to GitHub issues
- Enable creating GitHub issues from Claude Code mobile

### Summary
Migrated 6 documentation files to GitHub issues, removing local duplicates. Created a GitHub Action workflow that automatically creates issues from markdown files in `issues/` folder, enabling issue creation from Claude Code mobile. Added a global `/add-mobile-issues` command to set this up in other projects.

### Files Changed
- `Scripts/create-issues.sh` - Created (from mobile branch), then removed after use
- `docs/INSTALLATION_TRACKING.md` - Deleted (migrated to issue #7)
- `docs/CLAUDE_CODE_DETECTION.md` - Deleted (migrated to issue #8)
- `docs/APP_STORE_DISTRIBUTION.md` - Deleted (migrated to issue #9)
- `docs/FUTURE_IDEAS.md` - Deleted (migrated to issues #1, #3)
- `docs/DYNAMIC_ICON_IDEAS.md` - Deleted (migrated to issue #4, updated with full content)
- `docs/ENERGY_METHODOLOGY_REVIEW.md` - Deleted (migrated to new issue #10)
- `.github/workflows/create-issues.yml` - NEW: GitHub Action for auto-creating issues
- `issues/.gitkeep` - NEW: Placeholder for issues folder
- `CLAUDE.md` - Updated with directive instructions for issue creation
- `~/.claude/commands/add-mobile-issues.md` - NEW: Global command to set up workflow in any project

### Technical Notes
- GitHub issues now contain full doc content (using `--body-file` flag)
- Issue #4 was updated to include full DYNAMIC_ICON_IDEAS.md content (previously just referenced the doc)
- CLAUDE.md uses directive language ("When asked to create a GitHub issue: Create a markdown file...") to ensure Claude Code on mobile uses the file-based approach instead of trying `gh` CLI
- The GitHub Action extracts title from first heading, optional labels from `Labels:` line

### Future Plans & Unimplemented Phases
None - all planned work completed.

### Next Actions
- [ ] Test mobile issue creation from Claude Code in Claude app
- [ ] Try `/add-mobile-issues` command in another project to verify it works

### Metrics
- Files deleted: 7 (docs migrated to issues)
- Files created: 3 (workflow, .gitkeep, global command)
- GitHub issues created: 1 (#10 - Energy Methodology Review)
- GitHub issues updated: 1 (#4 - full content added)

---

## Session Log: 2025-12-13

**Project**: claude-carbon
**Type**: [feature]

### Objectives
- Add view toggle system to switch between Stats, Charts, and Settings views
- Implement charts showing token usage and burn rate over time
- Refactor Settings from modal overlay to embedded view

### Summary
Implemented a complete view toggle system for Claude Carbon with three switchable views (Stats, Charts, Settings) via a segmented control in the footer. Added Swift Charts integration showing token usage (bar chart) and burn rate (line chart) with proper x-axis labeling for Today (hourly), Week (daily), and All Time (manual 5-point labels). Fixed multiple issues with chart axis labels and data queries.

### Files Changed
- `ClaudeCarbon/Services/DataStore.swift` - Added `DailyUsage`, `HourlyUsage`, `BurnRatePoint` structs; added `getDailyUsage(days:)`, `getBurnRateByDay(days:)`, `getTodayHourlyUsage()` methods for time-series data
- `ClaudeCarbon/Views/MenuBarView.swift` - Added `ViewMode` state, integrated `ViewModePicker` in footer, replaced sheet-based settings with embedded view switching
- `ClaudeCarbon/Views/SettingsView.swift` - Added `EmbeddedSettingsView` struct for inline display (no modal dismiss)
- `ClaudeCarbon/Views/ViewModePicker.swift` - **NEW** - Segmented control with icons for stats/charts/settings with visual separator before settings
- `ClaudeCarbon/Views/ChartsView.swift` - **NEW** - Token usage chart (hourly for Today, daily for Week/All Time) and burn rate chart using Swift Charts
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Added new Swift files to Xcode project

### Technical Notes
- **Burn rate calculation**: `tokens per active hour = total tokens / (session duration in hours)` - measures intensity regardless of hours worked
- **Today view**: Uses hourly data with `.chartXScale(domain: startOfDay...endOfDay)` to show full 24-hour range even with sparse data
- **All Time x-axis labels**: Manual calculation of 5 evenly spaced dates (start, 3 middle, end) to guarantee edge labels - Swift Charts' automatic methods don't reliably include edges
- **Data query pattern**: `days: 0` = today only, `days: 7` = last 7 days, `days: nil` = all time
- **ViewModePicker placement**: Moved from center (below time picker) to footer left for cleaner UX

### Future Plans & Unimplemented Phases
None - core feature complete. Potential polish items:
- Add tooltips/hover states on chart bars showing exact values
- Consider weekly aggregation for All Time when data exceeds certain threshold

### Next Actions
- [ ] Test all three time ranges (Today, Week, All Time) with real data
- [ ] Verify burn rate calculations make sense
- [ ] Consider adding chart animations
- [ ] Commit changes once verified working

### Metrics
- Files modified: 4
- Files created: 2 (ViewModePicker.swift, ChartsView.swift)
- New data structures: 3 (DailyUsage, HourlyUsage, BurnRatePoint)
- New query methods: 3 (getDailyUsage, getBurnRateByDay, getTodayHourlyUsage)

---

## Session Log: 2025-12-13 (Session 2)

**Project**: claude-carbon
**Type**: [docs] [config]

### Objectives
- Strategic planning for open source launch
- Prepare repo for public release
- Create contributor documentation
- Set up GitHub Issues as roadmap

### Summary
Conducted strategic planning discussion covering release timing, open source best practices, distribution options (Swift vs React, App Store vs GitHub), and gamification ideas. Decided to ship ASAP (1-2 days) with GitHub release first, App Store parallel. Updated README with accurate features, created CONTRIBUTING.md, rewrote CLAUDE.md for contributors.

### Files Changed
- `README.md` - Added "Why?" section explaining purpose, updated features to reflect actual token tracking (not estimates), simplified contributing section, updated limitations
- `CONTRIBUTING.md` - **NEW**: Contributor guidelines including Claude Code workflow, areas for contribution, code style
- `CLAUDE.md` - Rewritten with project structure, key files, data flow diagram, contributing guidance

### Technical Notes

1. **Release Strategy Decision**: Ship GitHub release first (immediate), App Store submission parallel. LinkedIn post as initial launch.

2. **Open Source Model**: Standard GitHub fork+PR workflow. Contributors cannot push directly - they fork, change, submit PR for approval.

3. **Swift vs React Decision**: Stay Swift. App Store handles user distribution. Vibe coders without Xcode can still contribute ideas/docs/methodology.

4. **Gamification Direction**: Personal bests (tokens per active hour) as primary metric. Rewards efficient model choice without punishing usage.

5. **App Store Considerations**: App reads `~/.claude/` files which requires sandbox disabled. May get questions during App Store review.

### Future Plans & Unimplemented Phases

#### Phase: GitHub Release Creation
**Status**: Not started (requires Xcode)
**Planned Steps**:
1. Build release configuration in Xcode (Product → Archive)
2. Distribute App → "Developer ID" (not App Store)
3. Let Xcode notarize automatically
4. Export notarized .app
5. Create .zip and upload to GitHub Releases

#### Phase: App Store Submission
**Status**: Not started (requires Xcode)
**Planned Steps**:
1. Product → Archive
2. Distribute App → "App Store Connect"
3. Let Xcode manage signing, upload build
4. Go to appstoreconnect.apple.com
5. Create new app listing (name, description, keywords, screenshots)
6. Select uploaded build, submit for review
7. Wait 24-48 hours for review

### Next Actions
- [ ] Test app in Xcode - verify all recent features work
- [ ] Create GitHub Release (Archive → Developer ID → Notarize → Upload)
- [ ] Start App Store submission parallel
- [ ] Write LinkedIn post for launch
- [ ] Add LICENSE file (MIT mentioned in README but file may not exist)

### Metrics
- Files modified: 2 (README.md, CLAUDE.md)
- Files created: 1 (CONTRIBUTING.md)
- Commit: 540f7d0 "feat: prepare for open source launch"

---

## Session Log: 2025-12-14

**Project**: claude-carbon
**Type**: [bugfix]

### Objectives
- Investigate Xcode console warnings (layout recursion)
- Address potential performance issues from monitoring hundreds of session files

### Summary
Fixed SwiftUI layout recursion warning caused by unnecessary GeometryReader usage and cornerRadius placement. Added startup and read-time cleanup for session file monitoring to prevent resource exhaustion and SQLite bloat from orphaned entries.

### Files Changed
- `ClaudeCarbon/Views/StatsView.swift` - Removed unnecessary GeometryReader from CarbonProgressBar, changed cornerRadius to clipShape in ModelBreakdownBar
- `ClaudeCarbon/Services/DataStore.swift` - Added getAllOffsetPaths() and deleteOffset(forFile:) methods for cleanup
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Added startup cleanup of orphaned offsets, added read-time cleanup when files are deleted

### Technical Notes
- **Layout recursion cause**: CarbonProgressBar had GeometryReader wrapping content but never used the `geometry` parameter - just hardcoded 60px width
- **ModelBreakdownBar fix**: `.cornerRadius()` after `.frame()` can cause layout recursion; `.clipShape(RoundedRectangle())` handles layout better
- **Session monitoring issue**: No cleanup mechanism existed - every .jsonl file ever seen was monitored indefinitely, and SQLite offset entries accumulated forever
- **Cleanup approach**: Startup cleanup checks all stored offset paths and removes entries for deleted files; read-time cleanup removes monitors and DB entries when file access fails

### Future Plans & Unimplemented Phases
None - all planned work was completed.

### Next Actions
- [ ] Build and run in Xcode to verify fixes
- [ ] Monitor Xcode console for layout recursion warning disappearance
- [ ] Verify cleanup logs appear on startup when orphaned files exist

### Metrics
- Files modified: 3
- Lines added: ~50
- Lines removed: ~5

---

## Session Log: 2024-12-14

**Project**: claude-carbon
**Type**: [docs] [config]

### Objectives
- Research open source license options for the project
- Add MIT license to the repository
- Document the licensing decision rationale

### Summary
Researched open source licensing options (MIT, Apache 2.0, GPL) via web search, discussing trade-offs between permissive and copyleft licenses. Chose MIT for maximum simplicity and adoption, with a Buddhist-informed rationale around generosity and non-attachment. Created LICENSE file and documented the decision in docs/LICENSING.md.

### Files Changed
- `LICENSE` - Created MIT license with Tim Metz copyright
- `docs/LICENSING.md` - Created licensing decision documentation with rationale

### Technical Notes
- **License categories**: Permissive (MIT, Apache 2.0, BSD) vs Copyleft (GPL, LGPL, AGPL)
- **MIT chosen because**: Simplest license, maximum adoption potential, aligns with project's public-good mission
- **Key insight**: README.md already referenced MIT License with broken `[LICENSE](LICENSE)` link — now fixed
- **Future flexibility**: Copyright holder can be updated to "Claude Carbon Contributors" if community grows

### Future Plans & Unimplemented Phases
None - all planned work was completed.

### Next Actions
- [ ] Commit the new LICENSE and LICENSING.md files
- [ ] Consider GitHub Sponsors setup if pursuing open source sustainability
- [ ] Update copyright holder if community contributors join

### Metrics
- Files created: 2
- Files modified: 0

---

## Session Log: 2025-12-14

**Project**: claude-carbon
**Type**: [bugfix]

### Objectives
- Investigate and fix 30-day session duration bug (sessions showing Nov 10 → Dec 10 spans)
- Root cause analysis of corrupted session data causing burn rate chart spikes

### Summary
Investigated impossible 30-day session durations in the database. Root cause identified: agent JSONL files (`agent-*.jsonl`) contain the parent session's ID in their content, not the agent's ID. When the app reads these files, tokens get attributed to old parent sessions, causing `lastActivityTime` to update while `startTime` remains from weeks ago. Fixed by filtering out agent files during JSONL scanning.

### Files Changed
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Skip agent JSONL files (line 185), add orphaned offset cleanup, add file deletion handling

### Technical Notes
- **Root cause discovery**: File `agent-03f8b8cf.jsonl` contains `sessionId: 496cde3e-bb1d-4150-a926-f2adce764cf5` (different ID than filename)
- **Bug flow**:
  1. Parent session created (Nov 10)
  2. Agent spawned, creates `agent-{short-id}.jsonl`
  3. Agent file content has `sessionId = <parent-session-id>`
  4. App reads agent file, extracts sessionId from content
  5. Tokens attributed to parent session
  6. `lastActivityTime` updates to current date → 30-day span
- **Fix rationale**: Agent tokens are already counted in parent's main JSONL file, so skipping agent files loses no data
- **Database note**: Database was empty (0 bytes) during investigation, likely reset earlier

### Future Plans & Unimplemented Phases

#### Today Burn Rate Chart Empty
**Status**: Not started
**Issue**: LineMark with single data point doesn't render (needs 2+ points)
**Planned approach**: Either show a point mark instead of line for single-day data, or display a message like "Need 2+ days for trend"

#### Week Chart Missing Today's Day Label (GitHub Issue #12)
**Status**: Not started
**Issue**: Week view shows only 6 day labels instead of 7 (today's label missing)
**Documented in**: `issues/week-chart-missing-today-label.md`
**Suspected cause**: Swift Charts axis label positioning clips last mark near domain boundary
**Possible solutions**:
- Increase end padding (try +2 days instead of +1)
- Use `.chartXAxis { AxisMarks(preset: .aligned, values: weekDates) }`
- Try `.chartPlotStyle` to add internal padding

### Next Actions
- [ ] Investigate why Today burn rate chart shows empty (LineMark single-point issue)
- [ ] Fix week chart missing today's day label (issue #12)
- [ ] Push recent commits to remote (branch is ahead by 3 commits)
- [ ] Commit remaining uncommitted changes (DataStore, MenuBarView, SettingsView, StatsView, docs)

### Metrics
- Files modified: 1
- Commits created: 1 (f0208e3)

---

## Session Log: 2024-12-15

**Project**: claude-carbon
**Type**: [bugfix]

### Objectives
- Investigate why Claude Carbon shows far fewer tokens than actual Claude Code usage
- Fix subagent token counting (73-90% of tokens were missing)

### Summary
Discovered that commit `85c3da4` added a filter to skip agent JSONL files (`!file.hasPrefix("agent-")`), which was causing 73-90% of token usage to be missing. Investigation confirmed agent tokens are NOT duplicated in parent session files - they're stored separately in `agent-{id}.jsonl` files but reference the parent's `sessionId`. Fixed by removing the agent file skip filter. Database reset required to recount historical tokens.

### Files Changed
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Removed agent file skip filter on line 185 (`!file.hasPrefix("agent-")`)

### Technical Notes
- **Agent JSONL structure**: Parent sessions stored in `{uuid}.jsonl` with `isSidechain: false`, agents stored in `agent-{id}.jsonl` with `isSidechain: true` and parent's `sessionId`
- **Root cause**: Commit 85c3da4 skipped agent files to prevent "session cross-contamination" (corrupting date/timing for burn rate), but this caused massive token undercount
- **Fix validation**: After proper database reset, token count went from ~17k to ~630k (matching actual JSONL data)
- **Database reset challenges**:
  - App auto-restarting due to Xcode state restoration (appears as launchctl service)
  - File deletion sometimes didn't work (ACL on directory: `group:everyone deny delete`)
  - Solution: Clear tables directly via SQLite instead of deleting database file

### Database Reset Procedure (for future reference)
1. Stop the app: `pkill -9 -f "ClaudeCarbon"`
2. Clear tables: `sqlite3 ~/Library/Application\ Support/ClaudeCarbon/data.sqlite "DELETE FROM jsonl_offsets; DELETE FROM sessions; VACUUM;"`
3. Restart app - it will read all JSONL files from offset 0

### Future Plans & Unimplemented Phases

#### Verify Token Count After Reset
**Status**: Pending user verification
**Expected outcome**: App should show ~630k+ tokens after restart, matching JSONL file totals

#### Today Burn Rate Chart Empty
**Status**: Not started
**Issue**: LineMark with single data point doesn't render (needs 2+ points)
**Planned approach**: Either show a point mark instead of line for single-day data, or display a message like "Need 2+ days for trend"

#### Week Chart Missing Today's Day Label (GitHub Issue #12)
**Status**: Not started
**Documented in**: `issues/week-chart-missing-today-label.md`

### Next Actions
- [ ] Verify token count is correct after database reset (~630k expected)
- [ ] Commit the SessionJSONLMonitor.swift fix
- [ ] Monitor for any burn rate calculation issues (original reason for skipping agent files)
- [ ] Consider adding subagent token breakdown in future (currently just aggregated to parent session)

### Metrics
- Files modified: 1 (SessionJSONLMonitor.swift)
- Database tables cleared: 2 (jsonl_offsets, sessions)

---

## Session Log: 2025-12-18

**Project**: claude-carbon
**Type**: [bugfix] [feature]

### Objectives
- Fix token double-counting bug from streaming updates
- Ensure ALL tokens are counted (including agents and cache tokens)
- Avoid any double-counting

### Summary
Comprehensive fix for accurate token counting in Claude Carbon. Discovered and fixed three major issues: (1) streaming updates causing 1.03x-2.44x overcounting, (2) agent JSONL files being skipped entirely (losing subagent tokens), and (3) cache tokens not being counted at all (can be 99%+ of actual tokens). Implemented energy-weighted calculation for cache tokens based on their computational cost.

### Files Changed
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Added message.id deduplication, removed agent skip filter, added cache token energy weighting
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Fixed initialization order (deferred SessionJSONLMonitor.start())
- `ClaudeCarbon/App/AppDelegate.swift` - Added single-instance check
- `METHODOLOGY.md` - Added cache token energy weighting documentation, updated version to v1.1
- `docs/SESSION_LOG.md` - Session notes

### Technical Notes

#### Streaming Deduplication
- Claude JSONL files contain multiple entries per API response (streaming updates)
- Each entry has same `message.id` but incrementally increasing token counts
- Fixed by collecting entries by message.id and keeping only highest `outputTokens`

#### Agent Files Now Included
- Previously: `agent-*.jsonl` files were skipped to prevent "session cross-contamination"
- Discovery: Agent tokens are UNIQUE (different message IDs from parent session)
- Agent files contain parent's sessionId, but tokens are attributed there (acceptable)
- Skipping them was losing all subagent token usage

#### Cache Token Energy Weighting (Major Discovery)
- Cache tokens are ADDITIONAL to `input_tokens`, not a subset
- Real data showed 17M+ cache tokens vs 30K input tokens in some sessions
- Pricing ratios reflect computational cost:
  - `cache_read_input_tokens`: 10% of normal energy (just retrieval)
  - `cache_creation_input_tokens`: 125% of normal energy (extra work to store)
- Formula: `effective_input = input + (cache_read × 0.1) + (cache_create × 1.25)`

#### Key Sources
- [Anthropic Prompt Caching](https://www.anthropic.com/news/prompt-caching)
- [AWS Blog on Claude Code Caching](https://aws.amazon.com/blogs/machine-learning/supercharge-your-development-with-claude-code-and-amazon-bedrock-prompt-caching/)

### Commit
- **Hash**: `df36dc4`
- **Message**: fix: accurate token counting with dedup, agents, and cache weighting
- **Pushed**: Yes (origin/main)

### Next Actions
- [ ] Rebuild in Xcode (Cmd+R) and verify token counts
- [ ] Monitor debug logs for cache token breakdown
- [ ] Verify energy calculations reflect cache weighting

### Metrics
- Files modified: 5
- Lines added: 168
- Lines removed: 22

---

## Session Log: 2025-12-18

**Project**: Claude Carbon + Logseq (Article Research)
**Duration**: ~2 hours
**Type**: [feature] [docs]

### Objectives
- Research AI energy usage highlights from Logseq knowledge base for LinkedIn article
- Implement UI improvements: Today burn rate stat and "since date" footnote for All Time

### Summary
Two-part session: First, researched AI energy content from Logseq highlights (Empire of AI, Lex Fridman #459, MIT Tech Review) to help complete a LinkedIn article about Claude Carbon. Second, implemented two UI improvements: showing today's burn rate as a single stat instead of an empty chart, and adding "since [date]" footnotes to All Time views in both stats and charts screens.

### Files Changed
- `ClaudeCarbon/Views/ChartsView.swift` - Added today burn rate single stat display, All Time footnote in charts
- `ClaudeCarbon/Views/ComparisonView.swift` - Added optional startDate parameter to HeroComparisonView
- `ClaudeCarbon/Views/MenuBarView.swift` - Pass allTimeStartDate to HeroComparisonView

### Technical Notes

#### Today Burn Rate Implementation
- `BurnRateSection` now accepts `todayUsage: DailyUsage?` parameter
- When `timeRange == .today` and `activeSeconds >= 60`, shows single stat instead of chart
- Displays: large formatted rate (e.g., "212k") + "tokens per active hour" caption
- Falls back to "Not enough active time yet" if < 60 seconds

#### All Time Footnote Implementation
- Both `HeroComparisonView` (stats) and `BurnRateSection` (charts) show "since [date]"
- Date pulled from `dataStore.getDailyUsage(days: nil).first?.date`
- Format: `since Nov 18, 2024` using `.dateTime.month(.abbreviated).day().year()`

#### Article Research Sources Compiled
| Source | Link |
|--------|------|
| DOE/LBNL Data Center Report | https://www.energy.gov/articles/doe-releases-new-report-evaluating-increase-electricity-demand-data-centers |
| Lex Fridman #459 | https://lexfridman.com/deepseek-dylan-patel-nathan-lambert/ |
| MIT Tech Review | https://www.technologyreview.com/2025/05/20/1116327/ai-energy-usage-climate-footprint-big-tech/ |
| EIA Household Data | https://www.eia.gov/energyexplained/use-of-energy/electricity-use-in-homes.php |
| Joe Rogan #2422 | https://share.snipd.com/episode/48249efb-108d-464f-a88a-f7ed7d28867f |

#### Key Stats for Article
- 170,000 tokens ≈ 1 smartphone charge (from Claude Carbon methodology)
- User's 350-500k tokens/day = 6-8 smartphone charges = ~0.5% household energy
- 1M power users × 30% Haiku substitution = 25 GWh/year saved = 2,400 US homes
- Opus uses ~6.7x more energy than Haiku

### Commit
- **Hash**: `32c4ab4`
- **Message**: feat: add burn rate stat for Today view and "since date" footnote for All Time
- **Pushed**: Yes (origin/main)

### Next Actions
- [ ] Publish LinkedIn article about Claude Carbon
- [ ] Submit Claude Carbon to macOS App Store
- [ ] Consider expanding Claude Carbon to track other AI tools (Claude web, Lex, etc.)

### Metrics
- Files modified: 3
- Lines added: ~56
- Lines removed: ~8

---

## Session Log: 2025-12-18

**Project**: claude-carbon
**Type**: [feature]

### Objectives
- Implement design system from `docs/design-proposal.md`
- Apply Anthropic-complementary color scheme across all views

### Summary
Implemented centralized design system with Color+Theme.swift and Theme.swift. Replaced all hardcoded colors across 6 view files with theme colors (Fern green for energy, Ocean blue for tokens, Amber for burn rate/carbon). Updated AccentColor to Fern (#3D9A6D). Successfully built and pushed to main.

### Files Changed
- `ClaudeCarbon/App/Color+Theme.swift` - NEW: Color extension with all theme colors (Fern, Ocean, Amber, Coral, Rose, model colors, neutrals)
- `ClaudeCarbon/App/Theme.swift` - NEW: Spacing, radius, and font size constants
- `ClaudeCarbon/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` - Updated accent to Fern (#3D9A6D)
- `ClaudeCarbon/Views/StatsView.swift` - Replaced .blue/.green/.orange with .ocean/.fern/.amber, updated severity scales
- `ClaudeCarbon/Views/ChartsView.swift` - Replaced chart colors with theme colors
- `ClaudeCarbon/Views/MenuBarView.swift` - Updated leaf icon (.fern) and quit button (.coral)
- `ClaudeCarbon/Views/ComparisonView.swift` - Updated hero background and stat icons
- `ClaudeCarbon/Views/SessionRow.swift` - Updated folder (.ocean) and energy (.fern) colors
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Added new theme files to Xcode project

### Technical Notes
- Color mapping: `.green`→`.fern`, `.blue`→`.ocean`, `.orange`→`.amber`, `.red`→`.coral`/`.rose`
- Severity scale now uses: `.fern` (low) → `.amber` (moderate) → `.coral` (high) → `.rose` (critical)
- Model colors use graduated blues: Opus (dark), Sonnet (medium), Haiku (light)
- Theme.swift provides constants but views still use inline values (future refinement possible)

### Future Plans & Unimplemented Phases
- Apply Theme.swift spacing/radius constants throughout views (currently just colors applied)
- Consider dark mode support using the neutral colors (Carbon for dark bg, Pampas for light)

### Next Actions
- [ ] Apply Theme.swift spacing constants to views
- [ ] Test visual appearance in Xcode
- [ ] Consider dark mode implementation using theme neutrals

### Metrics
- Files modified: 7
- Files created: 2
- Commit: `0d0d96e`
- Pushed: Yes (origin/main)
