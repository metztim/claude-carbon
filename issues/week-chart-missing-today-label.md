# [Bug] Week chart missing today's day label
Labels: bug, charts

## Problem

In the Week view charts (Token Usage and Burn Rate), the axis shows only 6 day labels instead of 7. Today's day (e.g., "Sat" when today is Saturday) does not appear on the x-axis.

## Current Behavior

- Week view shows: Sun, Mon, Tue, Wed, Thu, Fri (6 labels)
- Expected: Sun, Mon, Tue, Wed, Thu, Fri, Sat (7 labels)
- The data bar for today IS rendered correctly, just the label is missing

## Technical Context

### What we've tried

1. **Domain extends past today**: The chart domain is set to `weekStart...endPadded` where `endPadded = today + 1 day`. This gives space for today's bar.

2. **Axis labels generated correctly**: We generate 7 dates using:
   ```swift
   let weekDates = (0..<7).compactMap {
       calendar.date(byAdding: .day, value: $0, to: weekStart)
   }
   ```
   This produces 7 dates including today.

3. **Data filtering works**: Data is filtered to `>= weekStart` to prevent left overflow.

### Suspected causes

1. **Swift Charts axis label positioning**: The last axis mark may be clipped or not rendered when it's close to the domain boundary, even though we added 1-day padding.

2. **Possible solutions to investigate**:
   - Increase end padding (try +2 days instead of +1)
   - Use `.chartXAxis { AxisMarks(preset: .aligned, values: weekDates) }`
   - Check if `centered: true` on `AxisValueLabel` affects edge labels
   - Try `.chartPlotStyle` to add internal padding

### Relevant code

`ClaudeCarbon/Views/ChartsView.swift`:
- Token Usage chart: lines ~137-210
- Burn Rate chart: lines ~266-330
- Both use the same pattern for week view axis labels

### Data flow

- `getDailyUsage(days: 7)` returns data from `today - 7 days` (potentially 8 days)
- We filter to `>= weekStart` (today - 6 days) to get exactly 7 days
- Domain: `weekStart` to `today + 1 day`
- Axis marks: 7 explicit dates from `weekStart` to `today`
