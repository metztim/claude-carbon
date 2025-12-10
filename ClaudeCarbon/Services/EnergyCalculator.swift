import Foundation
import Combine

/// Calculates energy consumption and carbon footprint from token counts
class EnergyCalculator: ObservableObject {
    private let methodology: Methodology

    init(methodology: Methodology = .default) {
        self.methodology = methodology
    }

    // MARK: - Energy Calculations

    /// Calculate energy and carbon estimates for given token counts
    /// - Parameters:
    ///   - inputTokens: Number of input tokens
    ///   - outputTokens: Number of output tokens
    ///   - model: Model name (default: "sonnet")
    /// - Returns: EnergyEstimate with calculated values
    func calculate(inputTokens: Int, outputTokens: Int, model: String = "sonnet") -> EnergyEstimate {
        let totalTokens = inputTokens + outputTokens
        let joulesPerToken = methodology.joulesPerToken[model] ?? methodology.joulesPerToken["sonnet"] ?? 1.0

        // Energy in Wh = (tokens × J/token × PUE) / 3600 (J per Wh)
        let energyJoules = Double(totalTokens) * joulesPerToken * methodology.pue
        let energyWh = energyJoules / 3600.0

        // Carbon in grams = energyWh × carbonIntensity(g/kWh) / 1000 (Wh per kWh)
        let carbonGrams = energyWh * methodology.carbonIntensity / 1000.0

        return EnergyEstimate(
            tokens: totalTokens,
            energyWh: energyWh,
            carbonGrams: carbonGrams,
            modelName: model
        )
    }

    /// Calculate energy for tokens with optional output multiplier
    /// - Parameters:
    ///   - tokens: Total token count
    ///   - model: Model name (default: "sonnet")
    ///   - includeOutputMultiplier: Apply output multiplier (default: false)
    /// - Returns: Energy estimate
    func calculate(tokens: Int, model: String = "sonnet", includeOutputMultiplier: Bool = false) -> EnergyEstimate {
        let joulesPerToken = methodology.joulesPerToken[model] ?? methodology.joulesPerToken["sonnet"] ?? 1.0
        let adjustedTokens = includeOutputMultiplier ? Int(Double(tokens) * methodology.outputMultiplier) : tokens

        let energyJoules = Double(adjustedTokens) * joulesPerToken * methodology.pue
        let energyWh = energyJoules / 3600.0
        let carbonGrams = energyWh * methodology.carbonIntensity / 1000.0

        return EnergyEstimate(
            tokens: adjustedTokens,
            energyWh: energyWh,
            carbonGrams: carbonGrams,
            modelName: model
        )
    }

    // MARK: - Bulk Calculations

    /// Calculate energy for multiple sessions with varying models
    /// - Parameter sessions: Array of sessions with token counts and model names
    /// - Returns: Combined energy estimate
    func calculateBatch(_ sessions: [(inputTokens: Int, outputTokens: Int, model: String)]) -> EnergyEstimate {
        var totalTokens = 0
        var totalEnergyWh = 0.0
        var totalCarbonGrams = 0.0

        for (inputTokens, outputTokens, model) in sessions {
            let estimate = calculate(inputTokens: inputTokens, outputTokens: outputTokens, model: model)
            totalTokens += estimate.tokens
            totalEnergyWh += estimate.energyWh
            totalCarbonGrams += estimate.carbonGrams
        }

        return EnergyEstimate(
            tokens: totalTokens,
            energyWh: totalEnergyWh,
            carbonGrams: totalCarbonGrams,
            modelName: "mixed"
        )
    }

    // MARK: - Utility Methods

    /// Get available models from methodology
    var availableModels: [String] {
        Array(methodology.joulesPerToken.keys).sorted()
    }

    /// Get joules per token for a specific model
    func joulesPerToken(for model: String) -> Double {
        methodology.joulesPerToken[model] ?? methodology.joulesPerToken["sonnet"] ?? 1.0
    }

    /// Get methodology's PUE value
    var pue: Double {
        methodology.pue
    }

    /// Get methodology's carbon intensity value
    var carbonIntensity: Double {
        methodology.carbonIntensity
    }
}
