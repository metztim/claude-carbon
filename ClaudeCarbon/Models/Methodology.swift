import Foundation

/// Configurable energy coefficients for AI energy calculations
struct Methodology: Codable {
    struct ModelData: Codable {
        let joulesPerToken: Double
        let confidence: String?
        let notes: String?
    }

    struct InfrastructureValue: Codable {
        let value: Double
        let confidence: String?
        let notes: String?
    }

    struct CarbonIntensity: Codable {
        let value: Double
        let unit: String?
        let confidence: String?
        let notes: String?
    }

    struct EstimationValue: Codable {
        let value: Double
        let confidence: String?
        let notes: String?
    }

    struct CharsPerTokenValue: Codable {
        let value: Int
        let notes: String?
    }

    struct Infrastructure: Codable {
        let pue: InfrastructureValue
        let carbonIntensity: CarbonIntensity
    }

    struct Estimation: Codable {
        let outputMultiplier: EstimationValue
        let charsPerToken: CharsPerTokenValue
    }

    let version: String?
    let lastUpdated: String?
    let sources: [String]?
    let models: [String: ModelData]
    let infrastructure: Infrastructure
    let estimation: Estimation

    /// Joules per token for each model (model name -> J/token)
    var joulesPerToken: [String: Double] {
        models.mapValues { $0.joulesPerToken }
    }

    /// Power Usage Effectiveness - datacenter overhead multiplier
    var pue: Double {
        infrastructure.pue.value
    }

    /// Carbon intensity in grams CO2 per kWh
    var carbonIntensity: Double {
        infrastructure.carbonIntensity.value
    }

    /// Multiplier for output tokens vs input tokens (generation is more expensive)
    var outputMultiplier: Double {
        estimation.outputMultiplier.value
    }

    /// Average characters per token for estimation
    var charsPerToken: Int {
        estimation.charsPerToken.value
    }

    /// Default methodology loaded from bundled Methodology.json
    static var `default`: Methodology {
        guard let url = Bundle.main.url(forResource: "Methodology", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let methodology = try? JSONDecoder().decode(Methodology.self, from: data) else {
            // Fallback if bundle resource not found
            return createFallback()
        }
        return methodology
    }

    private static func createFallback() -> Methodology {
        return Methodology(
            version: "1.0",
            lastUpdated: nil,
            sources: nil,
            models: [
                "sonnet": ModelData(joulesPerToken: 1.0, confidence: nil, notes: nil),
                "haiku": ModelData(joulesPerToken: 0.3, confidence: nil, notes: nil),
                "opus": ModelData(joulesPerToken: 2.0, confidence: nil, notes: nil)
            ],
            infrastructure: Infrastructure(
                pue: InfrastructureValue(value: 1.2, confidence: nil, notes: nil),
                carbonIntensity: CarbonIntensity(value: 384.0, unit: "gCO2e/kWh", confidence: nil, notes: nil)
            ),
            estimation: Estimation(
                outputMultiplier: EstimationValue(value: 2.5, confidence: nil, notes: nil),
                charsPerToken: CharsPerTokenValue(value: 4, notes: nil)
            )
        )
    }
}
