import SwiftUI

/// Main popover view for the menu bar app
struct MenuBarView: View {
    @ObservedObject var dataStore: DataStore
    @ObservedObject var historyMonitor: HistoryMonitor
    let energyCalculator: EnergyCalculator

    @State private var selectedTimeRange: TimeRange = .today
    @State private var showingSettings = false

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case allTime = "All Time"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Claude Carbon")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Current Session Section
                    if let sessionId = historyMonitor.currentSessionId {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Active Session")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            Text(sessionId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            if let lastPromptTime = historyMonitor.lastPromptTime {
                                Text(timeAgo(from: lastPromptTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Stats Section with Time Range Picker
                    VStack(spacing: 12) {
                        // Time Range Picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Stats Display
                        StatsView(
                            tokens: currentStats.tokens,
                            energyWh: currentStats.energyWh,
                            carbonG: currentStats.carbonG
                        )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)

                    // Household Comparison
                    if currentStats.energyWh > 0 {
                        ComparisonView(energyWh: currentStats.energyWh)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // Footer with Settings and Quit buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .padding()
        }
        .frame(width: 360, height: 480)
        .sheet(isPresented: $showingSettings) {
            SettingsView(energyCalculator: energyCalculator)
        }
    }

    // MARK: - Computed Properties

    private var currentStats: (tokens: Int, energyWh: Double, carbonG: Double) {
        switch selectedTimeRange {
        case .today:
            return dataStore.getTodayStats()
        case .week:
            return dataStore.getWeekStats()
        case .allTime:
            return dataStore.getAllTimeStats()
        }
    }

    // MARK: - Helper Methods

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
