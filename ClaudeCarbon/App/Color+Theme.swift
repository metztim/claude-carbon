import SwiftUI

extension Color {
    // MARK: - Primary (Fern green - environmental theme)
    static let fern = Color(hex: "3D9A6D")
    static let fernDark = Color(hex: "2D7A52")
    static let fernLight = Color(hex: "5CB88A")

    // MARK: - Secondary
    static let ocean = Color(hex: "3D7A9A")      // Token counts, data metrics
    static let amber = Color(hex: "9A7A3D")      // Warnings, burn rate
    static let coral = Color(hex: "9A5C4D")      // Errors, high usage alerts
    static let rose = Color(hex: "C15F5F")       // Critical/excessive usage

    // MARK: - Neutrals (shared with Anthropic)
    static let pampas = Color(hex: "F4F3EE")     // Light backgrounds
    static let cloudy = Color(hex: "B1ADA1")     // Borders, disabled
    static let stone = Color(hex: "6B6860")      // Secondary text
    static let carbon = Color(hex: "2A2825")     // Primary text, dark mode bg

    // MARK: - Model Colors (Claude variants)
    static let opus = Color(hex: "2D4A7A")       // Deep ocean blue
    static let sonnet = Color(hex: "4A7AB8")     // Medium sky blue
    static let haiku = Color(hex: "7AB8E8")      // Light airy blue

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
