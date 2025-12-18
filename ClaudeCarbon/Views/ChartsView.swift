import SwiftUI
import Charts

/// Charts view showing token usage and burn rate over time
struct ChartsView: View {
    @ObservedObject var dataStore: DataStore
    let timeRange: MenuBarView.TimeRange

    var body: some View {
        VStack(spacing: 16) {
            if timeRange == .today ? hourlyUsage.isEmpty : dailyUsage.isEmpty {
                emptyState
            } else {
                // Token usage chart
                TokensChartSection(
                    hourlyData: timeRange == .today ? hourlyUsage : nil,
                    dailyData: timeRange != .today ? dailyUsage : nil,
                    timeRange: timeRange
                )

                Divider()
                    .padding(.horizontal)

                // Burn rate chart
                BurnRateSection(
                    data: burnRateData,
                    timeRange: timeRange,
                    todayUsage: timeRange == .today ? dailyUsage.first : nil,
                    allTimeStartDate: timeRange == .allTime ? dailyUsage.first?.date : nil
                )
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Data

    private var hourlyUsage: [HourlyUsage] {
        dataStore.getTodayHourlyUsage()
    }

    private var dailyUsage: [DailyUsage] {
        let days: Int? = {
            switch timeRange {
            case .today: return 0  // 0 = today only
            case .week: return 7
            case .allTime: return nil
            }
        }()
        return dataStore.getDailyUsage(days: days)
    }

    private var burnRateData: [BurnRatePoint] {
        let days: Int? = {
            switch timeRange {
            case .today: return 0  // 0 = today only
            case .week: return 7
            case .allTime: return nil
            }
        }()
        return dataStore.getBurnRateByDay(days: days)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No data yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start using Claude Code to see your usage charts")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Token Usage Chart

private struct TokensChartSection: View {
    let hourlyData: [HourlyUsage]?
    let dailyData: [DailyUsage]?
    let timeRange: MenuBarView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.ocean)
                Text("Token Usage")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(totalTokensFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            if timeRange == .today, let hourlyData = hourlyData {
                // Hourly chart for today - show full 24 hour range
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                Chart(hourlyData) { item in
                    BarMark(
                        x: .value("Hour", item.date, unit: .hour),
                        y: .value("Tokens", item.tokens)
                    )
                    .foregroundStyle(Color.ocean.gradient)
                }
                .chartXScale(domain: startOfDay...endOfDay)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)), centered: true)
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let tokens = value.as(Int.self) {
                                Text(formatTokens(tokens))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 16)
            } else if let dailyData = dailyData {
                // Daily chart for week/all time
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
                let endPadded = calendar.date(byAdding: .day, value: 1, to: today)!

                // Filter data for week view to prevent overflow
                let chartData = timeRange == .week
                    ? dailyData.filter { $0.date >= weekStart }
                    : dailyData

                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Tokens", item.tokens)
                    )
                    .foregroundStyle(Color.ocean.gradient)
                }
                .chartXScale(domain: {
                    if timeRange == .allTime, let firstDate = dailyData.first?.date {
                        // Extend domain from first data point to today + padding
                        return firstDate...endPadded
                    } else {
                        // Week: fixed 7-day range (today - 6 days to today + padding)
                        return weekStart...endPadded
                    }
                }())
                .chartXAxis {
                    if timeRange == .week {
                        // Generate all 7 days regardless of data
                        let weekDates = (0..<7).compactMap {
                            calendar.date(byAdding: .day, value: $0, to: weekStart)
                        }
                        AxisMarks(values: weekDates) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            AxisGridLine()
                        }
                    } else {
                        // All Time - manually calculate 5 evenly spaced labels (start, 3 middle, end)
                        let axisValues: [Date] = {
                            guard let firstDate = dailyData.first?.date else { return [] }
                            let lastDate = today

                            let totalDays = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
                            let interval = totalDays / 4  // 4 intervals = 5 points

                            var values: [Date] = [firstDate]
                            for i in 1...3 {
                                if let date = calendar.date(byAdding: .day, value: interval * i, to: firstDate) {
                                    values.append(date)
                                }
                            }
                            values.append(lastDate)
                            return values
                        }()

                        AxisMarks(values: axisValues) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            AxisGridLine()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let tokens = value.as(Int.self) {
                                Text(formatTokens(tokens))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 16)
            }
        }
    }

    private var totalTokensFormatted: String {
        let total: Int
        if let hourlyData = hourlyData, timeRange == .today {
            total = hourlyData.reduce(0) { $0 + $1.tokens }
        } else if let dailyData = dailyData {
            total = dailyData.reduce(0) { $0 + $1.tokens }
        } else {
            total = 0
        }
        return "Total: \(formatTokens(total))"
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.0fk", Double(tokens) / 1_000)
        } else {
            return "\(tokens)"
        }
    }
}

// MARK: - Burn Rate Chart

private struct BurnRateSection: View {
    let data: [BurnRatePoint]
    let timeRange: MenuBarView.TimeRange
    let todayUsage: DailyUsage?  // For showing today's burn rate as single stat
    let allTimeStartDate: Date?  // For showing "since [date]" footnote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame")
                    .foregroundColor(.amber)
                Text("Burn Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(averageBurnRateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            if timeRange == .today, let usage = todayUsage, usage.activeSeconds >= 60 {
                // Today: show single stat instead of chart
                let activeHours = Double(usage.activeSeconds) / 3600.0
                let tokensPerHour = Double(usage.tokens) / activeHours

                VStack(spacing: 4) {
                    Text(formatRate(tokensPerHour))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.amber)
                    Text("tokens per active hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if data.isEmpty {
                Text(timeRange == .today ? "Not enough active time yet" : "Not enough session data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
                let endPadded = calendar.date(byAdding: .day, value: 1, to: today)!

                // Filter data for week view to prevent overflow
                let chartData = timeRange == .week
                    ? data.filter { $0.date >= weekStart }
                    : data

                Chart(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Tokens/hr", item.tokensPerActiveHour)
                    )
                    .foregroundStyle(Color.amber.gradient)

                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Tokens/hr", item.tokensPerActiveHour)
                    )
                    .foregroundStyle(Color.amber.opacity(0.1).gradient)
                }
                .chartXScale(domain: {
                    if timeRange == .week {
                        // Week: fixed 7-day range
                        return weekStart...endPadded
                    } else if let firstDate = data.first?.date {
                        return firstDate...endPadded
                    }
                    return today...endPadded
                }())
                .chartXAxis {
                    switch timeRange {
                    case .today:
                        AxisMarks(values: .automatic(desiredCount: 1)) { _ in
                            AxisValueLabel("Today")
                        }
                    case .week:
                        // Generate all 7 days regardless of data
                        let weekDates = (0..<7).compactMap {
                            calendar.date(byAdding: .day, value: $0, to: weekStart)
                        }
                        AxisMarks(values: weekDates) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            AxisGridLine()
                        }
                    case .allTime:
                        AxisMarks(preset: .aligned, values: .automatic(desiredCount: 5)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            AxisGridLine()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text(formatRate(rate))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 100)
                .padding(.horizontal, 16)
            }

            // Footer - hide "Tokens per active hour" when today's single stat is shown (already has that text)
            let showingSingleStat = timeRange == .today && (todayUsage?.activeSeconds ?? 0) >= 60
            if !showingSingleStat {
                HStack {
                    Text("Tokens per active hour")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                    Spacer()
                    if timeRange == .allTime, let startDate = allTimeStartDate {
                        Text("since \(startDate, format: .dateTime.month(.abbreviated).day().year())")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var averageBurnRateFormatted: String {
        guard !data.isEmpty else { return "" }
        let avg = data.reduce(0.0) { $0 + $1.tokensPerActiveHour } / Double(data.count)
        return "Avg: \(formatRate(avg))/hr"
    }

    private func formatRate(_ rate: Double) -> String {
        if rate >= 1_000_000 {
            return String(format: "%.1fM", rate / 1_000_000)
        } else if rate >= 1_000 {
            return String(format: "%.0fk", rate / 1_000)
        } else {
            return String(format: "%.0f", rate)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView(dataStore: DataStore(), timeRange: .week)
            .frame(width: 420)
    }
}
#endif
