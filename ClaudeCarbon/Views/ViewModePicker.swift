import SwiftUI

/// View modes for the main menu bar interface
enum ViewMode: CaseIterable {
    case stats
    case charts
    case settings

    var icon: String {
        switch self {
        case .stats: return "list.bullet"
        case .charts: return "chart.line.uptrend.xyaxis"
        case .settings: return "gear"
        }
    }

    var label: String {
        switch self {
        case .stats: return "Stats"
        case .charts: return "Charts"
        case .settings: return "Settings"
        }
    }
}

/// Segmented control for switching between views
struct ViewModePicker: View {
    @Binding var selection: ViewMode

    var body: some View {
        HStack(spacing: 2) {
            // Stats and Charts grouped together
            ForEach([ViewMode.stats, .charts], id: \.self) { mode in
                ViewModeButton(mode: mode, isSelected: selection == mode) {
                    selection = mode
                }
            }

            // Visual separator before settings
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 6)

            // Settings with slightly different treatment
            ViewModeButton(mode: .settings, isSelected: selection == .settings) {
                selection = .settings
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Individual button in the view mode picker
private struct ViewModeButton: View {
    let mode: ViewMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: mode.icon)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(mode.label)
    }
}

// MARK: - Preview

#if DEBUG
struct ViewModePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ViewModePicker(selection: .constant(.stats))
            ViewModePicker(selection: .constant(.charts))
            ViewModePicker(selection: .constant(.settings))
        }
        .padding()
    }
}
#endif
