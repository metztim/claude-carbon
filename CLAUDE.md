# Claude Carbon

macOS menu bar app tracking Claude Code token usage and environmental impact.

## Project Structure

```
ClaudeCarbon/
  App/              # App entry, delegates
  Models/           # Data structures (Session, Methodology)
  Services/         # Core logic (DataStore, Monitors, Coordinator)
  Views/            # SwiftUI components
  Resources/        # Assets, Methodology.json
Scripts/            # Installation hooks
docs/               # Documentation, session logs
```

## Key Files

- `Services/DataStore.swift` - SQLite persistence, stats queries
- `Services/SessionJSONLMonitor.swift` - Reads actual tokens from Claude's JSONL logs
- `Views/MenuBarView.swift` - Main popover UI
- `Views/ComparisonView.swift` - Energy equivalents display
- `METHODOLOGY.md` - Energy calculation methodology

## Building

Requires:
- macOS 14.0+
- Xcode 15+
- Swift 5.9+

Build and run with Xcode (Cmd+R).

## Contributing with Claude Code

1. Fork this repo and clone locally
2. Explore codebase: Review the file structure above
3. Browse issues: `gh issue list`
4. Claim an issue before starting work
5. Submit PRs with clear descriptions

### Ideas & Roadmap

See [GitHub Issues](https://github.com/metztim/claude-carbon/issues) labeled `enhancement` for feature ideas.

To propose a new idea: Create an issue with `[Idea]` prefix.

### Creating Issues

**When asked to create a GitHub issue:** Create a markdown file in `issues/` folder instead of using `gh` CLI. A GitHub Action will automatically create the issue on push.

Format:
```markdown
# [Feature] Title here
Labels: enhancement

Description...
```

Example: `issues/dark-mode.md` → push → Issue created automatically

## Data Flow

```
history.jsonl → HistoryMonitor → SessionCoordinator → DataStore
                                        ↑
projects/{path}/*.jsonl → SessionJSONLMonitor
```

Sessions created from history, tokens added from JSONL files.
