import SwiftUI

/// Household comparison display showing energy usage in relatable terms
struct ComparisonView: View {
    let energyWh: Double

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: comparisonIcon)
                .font(.title)
                .foregroundColor(.green)

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
        case 10.0..<100.0:
            return "laptopcomputer"
        default:
            return "house.fill"
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
                return String(format: "= Laptop for %.1f hour\(hours >= 2 ? "s" : "")", hours)
            }
        default:
            let kwh = energyWh / 1000.0
            return String(format: "= %.1f kWh of electricity", kwh)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ComparisonView(energyWh: 0.005)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 0.05)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 0.5)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 5.0)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            ComparisonView(energyWh: 50.0)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 360)
    }
}
#endif
