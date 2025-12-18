# [Docs] Document data persistence behavior
Labels: documentation

## Context

Users should understand how ClaudeCarbon stores data:

1. **ClaudeCarbon's SQLite database** - Stores token usage persistently forever
2. **Claude Code's JSONL files** - Only retained ~30 days by Claude Code

## What to document

- After a database reset, only ~30 days of history can be recovered (limited by Claude Code's retention)
- Going forward, ClaudeCarbon accumulates data indefinitely in its own database
- "All Time" shows all data ClaudeCarbon has captured, not necessarily your entire Claude Code history

## Where to add

- README.md under a "How it works" or "Data" section
- Possibly a tooltip in the app's "All Time" view
