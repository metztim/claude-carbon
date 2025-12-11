# App Store Distribution Requirements

> **Status**: Not Compatible (by design)
> **Priority**: Low
> **Labels**: documentation, distribution

## Executive Summary

Claude Carbon **cannot** be distributed via the Mac App Store in its current form due to disabled sandboxing. This is an intentional design decision to enable seamless access to Claude Code's data files.

## Current Architecture

### File Access Strategy

The app accesses `~/.claude/` directly using POSIX calls:

```swift
// From HistoryMonitor.swift and SessionJSONLMonitor.swift
let realHomeDirectory: String
if let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir {
    realHomeDirectory = String(cString: homeDir)
} else {
    realHomeDirectory = NSHomeDirectory()
}
```

### Entitlements Configuration

```xml
<!-- ClaudeCarbon.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>
```

Sandboxing is explicitly disabled to allow unrestricted file system access.

### Monitored Paths

| Path | Purpose |
|------|---------|
| `~/.claude/history.jsonl` | Claude Code session history |
| `~/.claude/projects/{path}/*.jsonl` | Actual token usage per session |
| `~/.claude/settings.json` | Hook configuration (modified by install script) |

## App Store Requirements vs Current State

| Requirement | Current State | App Store Requirement |
|-------------|---------------|----------------------|
| **Sandboxing** | Disabled | Must be enabled |
| **File access** | Direct path access | Security-scoped bookmarks |
| **User consent** | None required | Must use folder picker |
| **Code signing** | Development only | Developer ID + Team |
| **Notarization** | None | Required |
| **Privacy descriptions** | None | Required for file access |

## Why App Store Compatibility Is Hard

### The Sandbox Problem

When sandboxed:
- `NSHomeDirectory()` returns `~/Library/Containers/com.claudecarbon.app/Data/`
- App cannot see real `~/.claude/` directory
- Claude Code's files are completely inaccessible

### Required Changes for App Store

1. **Re-enable sandboxing**
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   ```

2. **Add folder picker on first launch**
   ```swift
   let panel = NSOpenPanel()
   panel.canChooseDirectories = true
   panel.canChooseFiles = false
   panel.prompt = "Select Claude Folder"
   panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory() + "/.claude")
   ```

3. **Store security-scoped bookmark**
   ```swift
   let bookmarkData = try url.bookmarkData(
       options: .withSecurityScope,
       includingResourceValuesForKeys: nil,
       relativeTo: nil
   )
   UserDefaults.standard.set(bookmarkData, forKey: "claudeFolderBookmark")
   ```

4. **Add entitlements for bookmarks**
   ```xml
   <key>com.apple.security.files.bookmarks.app-scope</key>
   <true/>
   <key>com.apple.security.files.user-selected.read-only</key>
   <true/>
   ```

5. **Add privacy descriptions to Info.plist**
   ```xml
   <key>NSDocumentsFolderUsageDescription</key>
   <string>Claude Carbon needs access to your Claude Code data folder to track token usage and calculate energy estimates.</string>
   ```

6. **Resolve bookmark on each launch**
   ```swift
   var isStale = false
   let url = try URL(
       resolvingBookmarkData: bookmarkData,
       options: .withSecurityScope,
       relativeTo: nil,
       bookmarkDataIsStale: &isStale
   )
   _ = url.startAccessingSecurityScopedResource()
   ```

## Current Distribution Model

### GitHub Releases (Recommended)

1. User downloads `.app` bundle from GitHub releases
2. Moves to `/Applications/`
3. Runs `./Scripts/install-hooks.sh`
4. Restarts Claude Code
5. Launches Claude Carbon

### Advantages of Direct Distribution

- No sandbox restrictions
- Seamless file access
- No folder picker required
- Simpler user experience (after initial setup)
- No App Store review process
- No annual developer fee required

### Disadvantages

- Users must allow "unidentified developer" apps
- No automatic updates via App Store
- Requires notarization for Gatekeeper (not yet configured)
- Less discoverable than App Store

## Notarization for Direct Distribution

Even without App Store, modern macOS requires notarization:

```bash
# Build for distribution
xcodebuild -scheme ClaudeCarbon -configuration Release archive

# Submit for notarization
xcrun notarytool submit ClaudeCarbon.app.zip \
    --apple-id "developer@example.com" \
    --team-id "TEAMID" \
    --password "@keychain:AC_PASSWORD"

# Staple ticket to app
xcrun stapler staple ClaudeCarbon.app
```

## Recommendation

**Continue with direct distribution** for the following reasons:

1. **Target audience**: Claude Code users are developers comfortable with GitHub
2. **Simplicity**: No folder picker, no bookmark management
3. **User experience**: Works immediately after setup
4. **Development velocity**: No App Store review delays

If App Store distribution becomes important later, consider creating a separate "Claude Carbon Lite" version with reduced functionality that works within sandbox constraints.

## Related Files

- `ClaudeCarbon/ClaudeCarbon.entitlements` - Sandbox configuration
- `ClaudeCarbon/Info.plist` - App configuration
- `ClaudeCarbon.xcodeproj/project.pbxproj` - Build settings
- `Scripts/install-hooks.sh` - Installation script

## References

- [Apple: App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [Apple: Security-Scoped Bookmarks](https://developer.apple.com/documentation/foundation/nsurl/1417051-bookmarkdata)
- [Apple: Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
