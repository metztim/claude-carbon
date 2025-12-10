import Foundation

/// Model representing energy calculation results
struct EnergyEstimate {
    let tokens: Int
    let energyWh: Double
    let carbonGrams: Double
    let modelName: String

    /// Human-readable comparison of energy usage to everyday items
    var householdComparison: String {
        switch energyWh {
        case 0..<0.01:
            return "Less than 1 second of LED bulb"
        case 0.01..<0.1:
            let seconds = Int(energyWh / 0.01)
            return "LED bulb for \(seconds) second\(seconds == 1 ? "" : "s")"
        case 0.1..<1.0:
            let seconds = Int(energyWh * 10)
            return "LED bulb for \(seconds) seconds"
        case 1.0..<10.0:
            let percent = String(format: "%.2f", energyWh * 0.05)
            return "Charging phone \(percent)%"
        case 10.0..<100.0:
            let seconds = Int(energyWh / 10.0 * 30)
            return "Laptop for \(seconds) seconds"
        default:
            let percent = String(format: "%.1f", energyWh * 0.05)
            return "Charging phone \(percent)%"
        }
    }
}
