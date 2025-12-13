# Claude Carbon Design Proposal
## Complementary Color Scheme & Typography

This document proposes a visual identity for Claude Carbon that is clearly complementary to Anthropic/Claude's branding while establishing its own distinct identity.

---

## Anthropic/Claude Reference

### Their Colors
| Name | Hex | Description |
|------|-----|-------------|
| Crail (Primary) | `#C15F3C` | Warm rust-orange |
| Cloudy | `#B1ADA1` | Warm grey neutral |
| Pampas | `#F4F3EE` | Off-white/cream |

### Their Typography
- **Styrene B** (Commercial Type) - Sans-serif for headlines/UI
- **Tiempos** (Klim Type Foundry) - Serif for body text
- Philosophy: "Both technically refined and charmingly quirky"

---

## Claude Carbon Proposed Identity

### Design Philosophy
Claude Carbon tracks environmental impact—our visual identity should evoke:
- **Nature/sustainability** (green tones)
- **Warmth and approachability** (matching Anthropic's human-centered feel)
- **Technical precision** (clean, modern typography)

---

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Fern** (Primary) | `#3D9A6D` | RGB(61, 154, 109) | Main accent, environmental indicators |
| **Fern Dark** | `#2D7A52` | RGB(45, 122, 82) | Pressed states, emphasis |
| **Fern Light** | `#5CB88A` | RGB(92, 184, 138) | Hover states, highlights |

*Fern green mirrors Crail's saturation (~54%) and luminosity (~42%) but in green hue (~150°), creating visual harmony.*

### Secondary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Ocean** | `#3D7A9A` | RGB(61, 122, 154) | Token counts, data metrics |
| **Amber** | `#9A7A3D` | RGB(154, 122, 61) | Warnings, burn rate |
| **Coral** | `#9A5C4D` | RGB(154, 92, 77) | Errors, high usage alerts |

*Secondary colors derived from the same saturation/luminosity family, rotated around the color wheel.*

### Neutral Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Pampas** | `#F4F3EE` | Anthropic's off-white | Light backgrounds |
| **Cloudy** | `#B1ADA1` | Anthropic's warm grey | Borders, disabled |
| **Stone** | `#6B6860` | RGB(107, 104, 96) | Secondary text |
| **Carbon** | `#2A2825` | RGB(42, 40, 37) | Primary text, dark mode bg |

*Borrowing Anthropic's warm neutrals creates direct visual connection.*

### Model-Specific Colors (Claude variants)

| Model | Hex | Description |
|-------|-----|-------------|
| Opus | `#2D4A7A` | Deep ocean blue |
| Sonnet | `#4A7AB8` | Medium sky blue |
| Haiku | `#7AB8E8` | Light airy blue |

### Severity Scale (Energy/Carbon)

| Level | Color | Hex | Range |
|-------|-------|-----|-------|
| Low | Fern | `#3D9A6D` | Minimal impact |
| Moderate | Amber | `#9A7A3D` | Moderate usage |
| High | Coral | `#9A5C4D` | High usage |
| Critical | Rose | `#C15F5F` | Excessive usage |

---

## Typography

### Primary Font: SF Pro (System)

For a native macOS app, SF Pro provides:
- Perfect system integration
- Excellent readability at all sizes
- Both text and display optical sizes
- Free and always available

**Usage:**
```swift
.font(.system(.body, design: .default))      // Body text
.font(.system(.headline, design: .rounded))  // Friendly headers
.font(.system(.caption, design: .monospaced)) // Technical data
```

### Alternative: Inter

If you want a distinct identity beyond system fonts:

| Font | Weight | Usage |
|------|--------|-------|
| Inter | Regular (400) | Body text |
| Inter | Medium (500) | Labels, emphasis |
| Inter | Semi-Bold (600) | Headlines |

*Inter shares Styrene's geometric precision while being open source.*

**Download:** https://fonts.google.com/specimen/Inter

### Numeric Display: JetBrains Mono

For token counts and statistics, a monospaced font ensures alignment:

```swift
.font(.custom("JetBrainsMono-Regular", size: 14))
```

*JetBrains Mono is free, readable, and technically-oriented.*

---

## SwiftUI Implementation

### Color Extension

```swift
import SwiftUI

extension Color {
    // MARK: - Primary
    static let fern = Color(hex: "3D9A6D")
    static let fernDark = Color(hex: "2D7A52")
    static let fernLight = Color(hex: "5CB88A")

    // MARK: - Secondary
    static let ocean = Color(hex: "3D7A9A")
    static let amber = Color(hex: "9A7A3D")
    static let coral = Color(hex: "9A5C4D")

    // MARK: - Neutrals
    static let pampas = Color(hex: "F4F3EE")
    static let cloudy = Color(hex: "B1ADA1")
    static let stone = Color(hex: "6B6860")
    static let carbon = Color(hex: "2A2825")

    // MARK: - Models
    static let opus = Color(hex: "2D4A7A")
    static let sonnet = Color(hex: "4A7AB8")
    static let haiku = Color(hex: "7AB8E8")

    // MARK: - Helpers
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
```

### Theme Constants

```swift
struct Theme {
    // Font sizes
    static let titleSize: CGFloat = 20
    static let headlineSize: CGFloat = 17
    static let bodySize: CGFloat = 14
    static let captionSize: CGFloat = 12

    // Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 12
    static let paddingLarge: CGFloat = 16

    // Corner radius
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 10
    static let radiusLarge: CGFloat = 14
}
```

---

## Visual Comparison

### Anthropic/Claude vs Claude Carbon

| Element | Claude | Claude Carbon |
|---------|--------|---------------|
| Primary | Crail (rust-orange) | Fern (forest green) |
| Feel | Warm, passionate | Fresh, sustainable |
| Neutrals | Pampas, Cloudy | Same (shared DNA) |
| Typography | Styrene | SF Pro / Inter |
| Icons | Abstract starburst | Leaf/nature motifs |

---

## Color Rationale

The **Fern** green (`#3D9A6D`) was derived by:

1. Taking Crail's HSL values: `H:15° S:54% L:50%`
2. Rotating hue by ~135° to green: `H:150°`
3. Keeping similar S/L for visual harmony: `S:43% L:42%`

This creates a green that:
- Has the same "weight" as Anthropic's orange
- Feels warm (not cold/clinical)
- Evokes nature and sustainability
- Is clearly distinct but complementary

---

## Next Steps

1. **Implement Color+Theme.swift** - Centralize all design constants
2. **Update Asset Catalog** - Set AccentColor to Fern
3. **Update Views** - Replace hardcoded colors with theme colors
4. **Consider custom fonts** - If Inter is desired, bundle as resource
5. **Create app icon** - Leaf or plant motif in Fern green

---

## Color Swatches Preview

```
Primary:    ████  Fern       #3D9A6D
            ████  Fern Dark  #2D7A52
            ████  Fern Light #5CB88A

Secondary:  ████  Ocean      #3D7A9A
            ████  Amber      #9A7A3D
            ████  Coral      #9A5C4D

Neutrals:   ████  Pampas     #F4F3EE
            ████  Cloudy     #B1ADA1
            ████  Stone      #6B6860
            ████  Carbon     #2A2825

Models:     ████  Opus       #2D4A7A
            ████  Sonnet     #4A7AB8
            ████  Haiku      #7AB8E8
```
