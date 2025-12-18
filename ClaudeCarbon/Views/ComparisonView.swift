import SwiftUI

// MARK: - Hero Comparison View (Large, prominent display)

/// Large hero display showing energy usage equivalent
struct HeroComparisonView: View {
    let energyWh: Double
    var startDate: Date? = nil  // Optional: shows "since [date]" footnote when provided

    var body: some View {
        HStack(spacing: 16) {
            // Large icon - fixed frame for consistency
            Image(systemName: comparisonIcon)
                .font(.system(size: 44))
                .foregroundColor(.fern)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Energy equivalent")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(comparisonText)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let startDate = startDate {
                    Text("since \(startDate, format: .dateTime.month(.abbreviated).day().year())")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(minHeight: 92) // Min height for consistency, allows growth for footnote
        .background(Color.fern.opacity(0.08))
        .cornerRadius(12)
    }

    private var comparisonIcon: String {
        switch energyWh {
        case 0..<1.0:
            return "lightbulb.fill"
        case 1.0..<10.0:
            return "iphone"
        case 10.0..<1000.0:
            return "laptopcomputer"
        case 1000.0..<100000.0:
            return "house.fill"
        default:
            return "car.fill"
        }
    }

    private var comparisonText: String {
        switch energyWh {
        case 0..<0.01:
            return "< 1 sec LED bulb"
        case 0.01..<0.1:
            let seconds = Int(energyWh / 0.01)
            return "LED bulb for \(seconds)s"
        case 0.1..<1.0:
            let seconds = Int(energyWh * 10)
            return "LED bulb for \(seconds)s"
        case 1.0..<10.0:
            let percent = energyWh * 0.05
            if percent < 1 {
                return String(format: "Phone charge %.1f%%", percent)
            } else {
                return String(format: "Phone charge %.0f%%", percent)
            }
        case 10.0..<100.0:
            let minutes = Int(energyWh / 10.0 * 5)
            return "Laptop for \(minutes) min"
        case 100.0..<1000.0:
            let hours = energyWh / 100.0
            if hours < 1 {
                let minutes = Int(hours * 60)
                return "Laptop for \(minutes) min"
            } else {
                return String(format: "Laptop for %.1f hrs", hours)
            }
        case 1000.0..<30000.0:
            let percent = Int(energyWh / 300.0)
            if percent < 100 {
                return "\(percent)% daily home use"
            } else {
                let days = energyWh / 30000.0
                return String(format: "%.1f days home power", days)
            }
        case 30000.0..<100000.0:
            let days = energyWh / 30000.0
            return String(format: "%.1f days home power", days)
        default:
            let miles = Int(energyWh / 1000.0 * 3.5)
            return "EV for \(miles) miles"
        }
    }
}

// MARK: - Compact Stats Row

/// Horizontal row showing tokens, energy, and carbon compactly
struct CompactStatsRow: View {
    let tokens: Int
    let tokensByModel: [String: Int]
    let energyWh: Double
    let carbonG: Double

    private let modelOrder = ["opus", "sonnet", "haiku"]

    var body: some View {
        HStack(spacing: 0) {
            // Tokens with model breakdown tooltip
            CompactStatItem(
                icon: "number.circle.fill",
                iconColor: .ocean,
                value: formattedTokens,
                label: "tokens"
            )
            .help(modelBreakdownTooltip)

            Spacer()

            // Energy
            CompactStatItem(
                icon: "bolt.circle.fill",
                iconColor: .fern,
                value: formattedEnergy,
                label: "energy"
            )

            Spacer()

            // Carbon
            CompactStatItem(
                icon: "leaf.circle.fill",
                iconColor: .amber,
                value: formattedCarbon,
                label: "CO₂"
            )
        }
    }

    private var modelBreakdownTooltip: String {
        let breakdown = modelOrder.compactMap { model -> String? in
            guard let count = tokensByModel[model], count > 0 else { return nil }
            return "\(model.capitalized): \(formatTokensForTooltip(count))"
        }
        if breakdown.isEmpty {
            return "No token breakdown available"
        }
        return breakdown.joined(separator: "\n")
    }

    private func formatTokensForTooltip(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.1fk", Double(tokens) / 1_000.0)
        } else {
            return "\(tokens)"
        }
    }

    private var formattedTokens: String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.0fk", Double(tokens) / 1_000.0)
        } else if tokens == 0 {
            return "0"
        } else {
            return "\(tokens)"
        }
    }

    private var formattedEnergy: String {
        if energyWh >= 1000 {
            return String(format: "%.1f kWh", energyWh / 1000.0)
        } else if energyWh >= 1 {
            return String(format: "%.0f Wh", energyWh)
        } else if energyWh == 0 {
            return "0 Wh"
        } else {
            return String(format: "%.2f Wh", energyWh)
        }
    }

    private var formattedCarbon: String {
        if carbonG >= 1000 {
            return String(format: "%.1f kg", carbonG / 1000.0)
        } else if carbonG >= 1 {
            return String(format: "%.0fg", carbonG)
        } else if carbonG == 0 {
            return "0g"
        } else {
            return String(format: "%.1fg", carbonG)
        }
    }
}

/// Single stat item for compact row
struct CompactStatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.body)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Legacy Comparison View (kept for compatibility)

/// Household comparison display showing energy usage in relatable terms
struct ComparisonView: View {
    let energyWh: Double

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: comparisonIcon)
                .font(.title)
                .foregroundColor(.fern)

            VStack(alignment: .leading, spacing: 4) {
                Text("Energy Impact")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(comparisonText)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var comparisonIcon: String {
        switch energyWh {
        case 0..<1.0:
            return "lightbulb.fill"
        case 1.0..<10.0:
            return "iphone"
        case 10.0..<1000.0:
            return "laptopcomputer"
        case 1000.0..<100000.0:
            return "house.fill"
        default:
            return "car.fill"
        }
    }

    private var comparisonText: String {
        switch energyWh {
        case 0..<0.01:
            return "Less than 1 second of LED bulb"
        case 0.01..<0.1:
            let seconds = Int(energyWh / 0.01)
            return "= LED bulb for \(seconds) second\(seconds == 1 ? "" : "s")"
        case 0.1..<1.0:
            let seconds = Int(energyWh * 10)
            return "= LED bulb for \(seconds) seconds"
        case 1.0..<10.0:
            let percent = energyWh * 0.05
            if percent < 1 {
                return String(format: "= Charging phone %.1f%%", percent)
            } else {
                return String(format: "= Charging phone %.0f%%", percent)
            }
        case 10.0..<100.0:
            let minutes = Int(energyWh / 10.0 * 5)
            return "= Laptop for \(minutes) minute\(minutes == 1 ? "" : "s")"
        case 100.0..<1000.0:
            let hours = energyWh / 100.0
            if hours < 1 {
                let minutes = Int(hours * 60)
                return "= Laptop for \(minutes) minutes"
            } else {
                return String(format: "= Laptop for %.1f hour%@", hours, hours >= 1.5 ? "s" : "")
            }
        case 1000.0..<30000.0:
            // Average US household uses ~30 kWh/day
            let percent = Int(energyWh / 300.0)
            if percent < 100 {
                return "= \(percent)% of daily household use"
            } else {
                let days = energyWh / 30000.0
                return String(format: "= %.1f days of household electricity", days)
            }
        case 30000.0..<100000.0:
            let days = energyWh / 30000.0
            return String(format: "= %.1f days of household electricity", days)
        default:
            // EV efficiency ~3.5 miles per kWh
            let miles = Int(energyWh / 1000.0 * 3.5)
            return "= Driving an EV \(miles) miles"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ComparisonView(energyWh: 0.05)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 5.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 50.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 500.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 10500.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 45000.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 150000.0)
                .padding()
                .background(Color.fern.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 360)
    }
}
#endif
