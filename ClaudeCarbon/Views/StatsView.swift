import SwiftUI

/// Statistics display card showing tokens, energy, and carbon
struct StatsView: View {
    let tokens: Int
    let energyWh: Double
    let carbonG: Double
    let tokensByModel: [String: Int]

    var body: some View {
        VStack(spacing: 16) {
            // Tokens Row
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedTokens)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()
                }

                // Model breakdown bar
                if !tokensByModel.isEmpty && tokens > 0 {
                    ModelBreakdownBar(tokensByModel: tokensByModel, totalTokens: tokens)
                }
            }

            Divider()

            // Energy Row
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Energy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedEnergy)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Visual indicator
                if energyWh > 0 {
                    Circle()
                        .fill(energyColor)
                        .frame(width: 12, height: 12)
                }
            }

            Divider()

            // Carbon Row
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Carbon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedCarbon)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Progress bar for carbon intensity
                if carbonG > 0 {
                    CarbonProgressBar(grams: carbonG)
                }
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var formattedTokens: String {
        if tokens >= 1_000_000 {
            return String(format: "%.2f M", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.1f k", Double(tokens) / 1_000.0)
        } else if tokens == 0 {
            return "0"
        } else {
            return "\(tokens)"
        }
    }

    private var formattedEnergy: String {
        if energyWh >= 1000 {
            return String(format: "%.2f kWh", energyWh / 1000.0)
        } else if energyWh >= 1 {
            return String(format: "%.2f Wh", energyWh)
        } else if energyWh == 0 {
            return "0 Wh"
        } else {
            return String(format: "%.3f Wh", energyWh)
        }
    }

    private var formattedCarbon: String {
        if carbonG >= 1000 {
            return String(format: "%.2f kg CO₂e", carbonG / 1000.0)
        } else if carbonG >= 1 {
            return String(format: "%.1f g CO₂e", carbonG)
        } else if carbonG == 0 {
            return "0 g CO₂e"
        } else {
            return String(format: "%.2f g CO₂e", carbonG)
        }
    }

    private var energyColor: Color {
        switch energyWh {
        case 0..<1:
            return .green
        case 1..<10:
            return .yellow
        case 10..<100:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Carbon Progress Bar

struct CarbonProgressBar: View {
    let grams: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 60, height: 6)
                    .cornerRadius(3)

                // Progress
                Rectangle()
                    .fill(progressColor)
                    .frame(width: min(60, progress * 60), height: 6)
                    .cornerRadius(3)
            }
        }
        .frame(width: 60, height: 6)
    }

    private var progress: Double {
        // Scale: 0-100g = 0-100%
        min(1.0, grams / 100.0)
    }

    private var progressColor: Color {
        switch grams {
        case 0..<10:
            return .green
        case 10..<50:
            return .yellow
        case 50..<100:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Model Breakdown Bar

struct ModelBreakdownBar: View {
    let tokensByModel: [String: Int]
    let totalTokens: Int

    // Model colors - blue variants to match token section theme
    private let modelColors: [String: Color] = [
        "opus": Color(red: 0.1, green: 0.2, blue: 0.6),    // Dark navy
        "sonnet": Color(red: 0.2, green: 0.4, blue: 0.9),  // Medium blue
        "haiku": Color(red: 0.4, green: 0.7, blue: 1.0)    // Light blue
    ]

    // Consistent ordering
    private let modelOrder = ["opus", "sonnet", "haiku"]

    var body: some View {
        VStack(spacing: 4) {
            // Stacked bar
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    ForEach(sortedModels, id: \.0) { model, tokens in
                        let width = geometry.size.width * CGFloat(tokens) / CGFloat(totalTokens)
                        Rectangle()
                            .fill(modelColors[model] ?? .gray)
                            .frame(width: max(width, tokens > 0 ? 2 : 0))
                    }
                }
            }
            .frame(height: 8)
            .cornerRadius(4)

            // Legend
            HStack(spacing: 12) {
                ForEach(sortedModels, id: \.0) { model, tokens in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(modelColors[model] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text("\(model.capitalized): \(formatTokens(tokens))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var sortedModels: [(String, Int)] {
        modelOrder.compactMap { model in
            if let tokens = tokensByModel[model], tokens > 0 {
                return (model, tokens)
            }
            return nil
        }
    }

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.0fk", Double(tokens) / 1_000.0)
        } else {
            return "\(tokens)"
        }
    }
}
