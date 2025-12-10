import SwiftUI

/// Settings panel for configuring energy calculation parameters
struct SettingsView: View {
    let energyCalculator: EnergyCalculator

    @State private var sonnetJoules: String = ""
    @State private var haikuJoules: String = ""
    @State private var opusJoules: String = ""
    @State private var pueValue: String = ""
    @State private var carbonIntensity: String = ""
    @State private var outputMultiplier: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.title)
                            Text("Claude Carbon Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Configure energy and carbon calculation parameters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Model Energy Coefficients
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Model Energy (Joules per Token)")
                                .font(.headline)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Sonnet 4.5")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("1.0", text: $sonnetJoules)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                    Text("J/token")
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Haiku 3.5")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("0.3", text: $haikuJoules)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                    Text("J/token")
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Opus 4.5")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("2.0", text: $opusJoules)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                    Text("J/token")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }

                    // Infrastructure Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Infrastructure")
                                .font(.headline)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("PUE")
                                        .frame(width: 140, alignment: .leading)
                                    TextField("1.2", text: $pueValue)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)

                                    Button(action: {
                                        showInfo(title: "PUE (Power Usage Effectiveness)",
                                               message: "Datacenter overhead multiplier. Typical range: 1.1-1.5. Lower is better.")
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }

                                HStack {
                                    Text("Carbon Intensity")
                                        .frame(width: 140, alignment: .leading)
                                    TextField("384", text: $carbonIntensity)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                    Text("gCO₂e/kWh")
                                        .foregroundColor(.secondary)

                                    Button(action: {
                                        showInfo(title: "Carbon Intensity",
                                               message: "Grams of CO₂ equivalent per kilowatt-hour. Global average: ~384 gCO₂e/kWh")
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                    }

                    // Estimation Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Estimation")
                                .font(.headline)

                            HStack {
                                Text("Output Multiplier")
                                    .frame(width: 140, alignment: .leading)
                                TextField("2.5", text: $outputMultiplier)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Text("×")
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    showInfo(title: "Output Multiplier",
                                           message: "Generation (output) typically uses more energy than processing input. Conservative estimate: 2.5×")
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }

                    // Methodology Link
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Methodology")
                            .font(.headline)

                        Button(action: openMethodology) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("View METHODOLOGY.md")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: resetToDefaults) {
                            Text("Reset to Defaults")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Text("Close")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(24)
            }
            .frame(minWidth: 500, minHeight: 600)
            .navigationTitle("Settings")
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentValues() {
        // Load current values from energyCalculator
        sonnetJoules = String(format: "%.2f", energyCalculator.joulesPerToken(for: "sonnet"))
        haikuJoules = String(format: "%.2f", energyCalculator.joulesPerToken(for: "haiku"))
        opusJoules = String(format: "%.2f", energyCalculator.joulesPerToken(for: "opus"))
        pueValue = String(format: "%.2f", energyCalculator.pue)
        carbonIntensity = String(format: "%.1f", energyCalculator.carbonIntensity)

        // Load output multiplier from methodology
        // Note: This would require access to the methodology instance
        // For now, use a default value
        outputMultiplier = "2.5"
    }

    private func resetToDefaults() {
        sonnetJoules = "1.00"
        haikuJoules = "0.30"
        opusJoules = "2.00"
        pueValue = "1.20"
        carbonIntensity = "384.0"
        outputMultiplier = "2.5"
    }

    private func openMethodology() {
        // Open METHODOLOGY.md in default browser or text editor
        if let url = Bundle.main.url(forResource: "METHODOLOGY", withExtension: "md") {
            NSWorkspace.shared.open(url)
        } else {
            // Try to open from project directory
            let projectPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Developer/Projects/Personal/ai-watchdog/claude-carbon")
            let methodologyPath = projectPath.appendingPathComponent("METHODOLOGY.md")

            if FileManager.default.fileExists(atPath: methodologyPath.path) {
                NSWorkspace.shared.open(methodologyPath)
            }
        }
    }

    private func showInfo(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(energyCalculator: EnergyCalculator())
    }
}
#endif
