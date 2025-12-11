import SwiftUI

/// Main popover view for the menu bar app
struct MenuBarView: View {
    @ObservedObject var dataStore: DataStore
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
            // Header with title and time picker
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Claude Carbon")
                    .font(.headline)

                Spacer()

                // Compact time picker
                Picker("", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Hero: Energy Impact Equivalent
            HeroComparisonView(energyWh: currentStats.energyWh)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)

            Divider()

            // Compact stats row
            CompactStatsRow(
                tokens: currentStats.tokens,
                tokensByModel: currentStats.tokensByModel,
                energyWh: currentStats.energyWh,
                carbonG: currentStats.carbonG
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Footer
            HStack {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 420)
        .sheet(isPresented: $showingSettings) {
            SettingsView(energyCalculator: energyCalculator)
        }
    }

    // MARK: - Computed Properties

    private var currentStats: UsageStats {
        switch selectedTimeRange {
        case .today:
            return dataStore.getTodayStats()
        case .week:
            return dataStore.getWeekStats()
        case .allTime:
            return dataStore.getAllTimeStats()
        }
    }

}
