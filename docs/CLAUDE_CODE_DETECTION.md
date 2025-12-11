# Claude Code Detection & Missing Installation Handling

> **Status**: Partially Implemented
> **Priority**: Medium
> **Labels**: enhancement, ux

## Current Behavior

When Claude Code is not installed, the app:

1. **Silently fails** - No user-visible error or guidance
2. **Logs to console** - Only visible in Xcode/Console.app
3. **Shows empty UI** - Menu bar appears with zero stats

### Current Detection Code

```swift
// HistoryMonitor.swift:56-61
guard FileManager.default.fileExists(atPath: self.historyPath) else {
    print("HistoryMonitor: history.jsonl not found at \(self.historyPath)")
    print("HistoryMonitor: Claude Code may not be installed or history file not yet created")
    return
}
```

```swift
// SessionJSONLMonitor.swift:95-98
guard FileManager.default.fileExists(atPath: projectsPath) else {
    print("SessionJSONLMonitor: Projects directory not found at \(projectsPath)")
    return
}
```

## Problem

Users who install Claude Carbon without Claude Code (or before using Claude Code) see:
- Empty statistics (0 tokens, 0 Wh, 0g CO2)
- No explanation of why
- No guidance on what to do

This creates confusion and a poor first impression.

## Proposed Solution

### 1. Add Detection State

```swift
enum ClaudeCodeStatus {
    case notInstalled      // ~/.claude/ doesn't exist
    case installedNoData   // ~/.claude/ exists but no history.jsonl
    case ready             // history.jsonl exists, ready to monitor
    case noHooksConfigured // Claude Code installed but hooks not set up
}

class ClaudeCodeDetector: ObservableObject {
    @Published var status: ClaudeCodeStatus = .notInstalled

    func checkStatus() {
        let claudeDir = homeDirectory + "/.claude"
        let historyFile = claudeDir + "/history.jsonl"
        let settingsFile = claudeDir + "/settings.json"

        guard FileManager.default.fileExists(atPath: claudeDir) else {
            status = .notInstalled
            return
        }

        guard FileManager.default.fileExists(atPath: historyFile) else {
            status = .installedNoData
            return
        }

        // Check if hooks are configured
        if let settings = try? loadSettings(from: settingsFile),
           settings.hooks?.isEmpty == false {
            status = .ready
        } else {
            status = .noHooksConfigured
        }
    }
}
```

### 2. Add User-Facing UI

#### Empty State View

```swift
struct EmptyStateView: View {
    let status: ClaudeCodeStatus

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let action = actionButton {
                action
            }
        }
        .padding()
    }

    var icon: String {
        switch status {
        case .notInstalled: return "exclamationmark.triangle"
        case .installedNoData: return "clock"
        case .noHooksConfigured: return "gear.badge"
        case .ready: return "checkmark.circle"
        }
    }

    var title: String {
        switch status {
        case .notInstalled: return "Claude Code Not Found"
        case .installedNoData: return "Waiting for First Session"
        case .noHooksConfigured: return "Setup Required"
        case .ready: return "Ready"
        }
    }

    var message: String {
        switch status {
        case .notInstalled:
            return "Install Claude Code to start tracking your AI energy usage.\n\nnpm install -g @anthropic/claude-code"
        case .installedNoData:
            return "Start a Claude Code session to begin tracking. Your usage will appear here automatically."
        case .noHooksConfigured:
            return "Run the setup script to enable real-time tracking:\n\n./Scripts/install-hooks.sh"
        case .ready:
            return "Claude Carbon is monitoring your Claude Code usage."
        }
    }
}
```

#### Menu Bar Indicator

Show status in menu bar icon:
- Normal icon: Claude Code detected and working
- Dimmed/gray icon: Claude Code not found
- Badge/dot: Setup required

### 3. Periodic Re-checking

```swift
class ClaudeCodeDetector {
    private var timer: Timer?

    func startPeriodicCheck() {
        // Check every 30 seconds until Claude Code is detected
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkStatus()
            if self?.status == .ready {
                self?.timer?.invalidate()
            }
        }
    }
}
```

### 4. Deep Link to Installation

Add "Install Claude Code" button that opens:
```swift
NSWorkspace.shared.open(URL(string: "https://docs.anthropic.com/en/docs/claude-code")!)
```

## User Flows

### Flow 1: User Has Claude Code Installed

1. Launch Claude Carbon
2. App detects `~/.claude/history.jsonl`
3. Shows normal stats UI
4. Done

### Flow 2: User Doesn't Have Claude Code

1. Launch Claude Carbon
2. App detects missing `~/.claude/`
3. Shows "Claude Code Not Found" empty state
4. User clicks "Learn More" → Opens Anthropic docs
5. User installs Claude Code
6. App auto-detects on next check → Shows "Waiting for First Session"
7. User starts Claude Code session
8. App detects data → Shows normal stats

### Flow 3: Claude Code Installed, No Hooks

1. Launch Claude Carbon
2. App detects `~/.claude/` but no hooks in settings
3. Shows "Setup Required" with script instructions
4. User runs `./Scripts/install-hooks.sh`
5. User restarts Claude Code
6. App shows normal stats

## Implementation Priority

1. **High**: Empty state UI for "not installed" case
2. **Medium**: Detect "no hooks configured" state
3. **Low**: Periodic re-checking
4. **Low**: Menu bar status indicator

## Related Files

- `ClaudeCarbon/Services/HistoryMonitor.swift` - Add status publishing
- `ClaudeCarbon/Services/SessionJSONLMonitor.swift` - Add status publishing
- `ClaudeCarbon/Views/MenuBarView.swift` - Show empty state
- `ClaudeCarbon/App/ClaudeCarbonApp.swift` - Initialize detector

## Testing Scenarios

1. Fresh macOS with no Claude Code
2. Claude Code installed, never used
3. Claude Code installed and used, no hooks
4. Claude Code fully configured
5. Claude Code uninstalled while app running
6. `~/.claude/` deleted while app running
