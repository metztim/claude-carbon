import SwiftUI

/// Compact settings panel for menu bar app
struct SettingsView: View {
    let energyCalculator: EnergyCalculator
    @Environment(\.dismiss) private var dismiss
    @State private var showingMethodology = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Current assumptions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calculation Assumptions")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        SettingsRow(label: "Opus", value: "2.0 J/token")
                        SettingsRow(label: "Sonnet", value: "1.0 J/token")
                        SettingsRow(label: "Haiku", value: "0.3 J/token")
                        Divider().padding(.vertical, 4)
                        SettingsRow(label: "PUE", value: "1.2×")
                        SettingsRow(label: "Carbon intensity", value: "384 gCO₂/kWh")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Divider()

                // Methodology
                DisclosureGroup(isExpanded: $showingMethodology) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Energy = tokens × J/token × PUE")
                            .font(.system(.caption, design: .monospaced))

                        Text("Estimates based on AI energy research. Output tokens use ~2.5× more energy than input tokens. Carbon calculated using US grid average.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("How it works")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()

            Spacer()
        }
        .frame(width: 300, height: 320)
    }
}

/// Single row in settings
struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Methodology View

/// Methodology and calculation info view
struct MethodologyView: View {
    @Environment(\.openURL) private var openURL

    private let methodologyURL = URL(string: "https://github.com/metztim/claude-carbon/blob/main/METHODOLOGY.md")!

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // How it works - at the top, always visible
            VStack(alignment: .leading, spacing: 8) {
                Text("How It Works")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Energy = tokens × J/token × PUE")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.vertical, 4)

                Text("We estimate energy by multiplying your token usage by research-based energy coefficients, then applying data center overhead (PUE). Estimates are accurate to within 2-4× — the order of magnitude is reliable, absolute values less so.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Calculation assumptions
            VStack(alignment: .leading, spacing: 8) {
                Text("Assumptions")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 4) {
                    SettingsRow(label: "Opus", value: "2.0 J/token")
                    SettingsRow(label: "Sonnet", value: "1.0 J/token")
                    SettingsRow(label: "Haiku", value: "0.3 J/token")
                    Divider().padding(.vertical, 4)
                    SettingsRow(label: "PUE", value: "1.2×")
                    SettingsRow(label: "Carbon intensity", value: "384 gCO₂/kWh")
                    SettingsRow(label: "Cache read", value: "0.1× energy")
                    SettingsRow(label: "Cache create", value: "1.25× energy")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Divider()

            // Full methodology link
            Button(action: { openURL(methodologyURL) }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Full Methodology")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            Divider()

            // Open source notice
            VStack(alignment: .leading, spacing: 4) {
                Text("Open Source")
                    .font(.caption)
                    .fontWeight(.medium)

                Text("MIT License. Contributions welcome — review the calculations, suggest improvements, or help make the estimates more accurate.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(energyCalculator: EnergyCalculator())
                .previewDisplayName("Modal")

            MethodologyView()
                .frame(width: 420)
                .previewDisplayName("Methodology")
        }
    }
}
#endif
