# Installation Date Tracking

> **Status**: Not Implemented
> **Priority**: Medium
> **Labels**: enhancement, analytics

## Current State

The app currently has **no installation tracking**:
- No first-run detection
- No install date stored
- Zero UserDefaults usage (app uses SQLite only)

However, the app **does** automatically backfill all historical Claude Code data on first launch by reading JSONL files from byte 0.

## Proposed Feature

Track when Claude Carbon was installed to enable before/after usage analysis.

### Why This Matters

With installation date tracking, we can answer:
- *"Did installing Claude Carbon reduce this user's token footprint?"*
- *"How does awareness of energy usage affect behavior over time?"*
- *"What's the average token reduction after X days of using the app?"*

## Implementation Options

### Option A: Explicit Install Date (Recommended)

Store installation timestamp on first launch:

```swift
// In AppDelegate or DataStore initialization
private func recordInstallDateIfNeeded() {
    let key = "installDate"
    if UserDefaults.standard.object(forKey: key) == nil {
        UserDefaults.standard.set(Date(), forKey: key)
    }
}

// Retrieve later
var installDate: Date? {
    UserDefaults.standard.object(forKey: "installDate") as? Date
}
```

**Pros:**
- Simple, reliable
- Exact timestamp
- Works even if no historical data exists

**Cons:**
- Requires UserDefaults (currently unused)

### Option B: Database-Based Tracking

Add install date to SQLite schema:

```sql
CREATE TABLE IF NOT EXISTS app_metadata (
    key TEXT PRIMARY KEY,
    value TEXT
);

-- On first launch
INSERT OR IGNORE INTO app_metadata (key, value)
VALUES ('install_date', datetime('now'));
```

**Pros:**
- Keeps all data in SQLite (consistent with current architecture)
- Can add other metadata later

**Cons:**
- Slightly more complex

### Option C: Infer from Session Data

Use earliest session timestamp as proxy:

```swift
func getInstallDate() -> Date? {
    // First session after app was installed
    return dataStore.getEarliestSessionDate()
}

func getBaselineDate() -> Date? {
    // Earliest historical session (pre-install)
    return dataStore.getEarliestHistoricalSessionDate()
}
```

**Pros:**
- No new storage needed
- Automatically available

**Cons:**
- Not exact install date
- Doesn't work if user had no prior Claude Code history

## Analytics Opportunities

Once install date is tracked, we can compute:

### Before/After Comparison

```swift
struct UsageComparison {
    let preInstallDailyAverage: Double   // tokens/day before install
    let postInstallDailyAverage: Double  // tokens/day after install
    let percentageChange: Double          // reduction (negative) or increase
    let daysTracked: Int
}
```

### Trend Analysis

```swift
struct UsageTrend {
    let weeklyAverages: [(week: Int, tokens: Int)]
    let trendDirection: TrendDirection  // .decreasing, .stable, .increasing
    let confidenceLevel: Double
}
```

### Potential UI Display

```
Your Impact
───────────
Using Claude Carbon for: 14 days
Pre-install average: 125K tokens/day
Current average: 98K tokens/day
Reduction: 21.6% fewer tokens
```

## Data Privacy Considerations

- All data stays local (no telemetry)
- User can clear data at any time
- Install date is not sensitive information
- Consider adding "Reset Statistics" option in future

## Related Files

- `ClaudeCarbon/Services/DataStore.swift` - Add install date storage
- `ClaudeCarbon/Models/Session.swift` - Session timestamps for inference
- `ClaudeCarbon/Views/StatsView.swift` - Display before/after comparison

## References

- Current backfill logic: `SessionJSONLMonitor.swift:196-204`
- Database schema: `DataStore.swift:40-60`
