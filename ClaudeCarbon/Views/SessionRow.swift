import SwiftUI

/// Single session display row
struct SessionRow: View {
    let session: Session
    let energyEstimate: EnergyEstimate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Project indicator icon
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                // Project name
                Text(projectName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    // Token count
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption2)
                        Text(formattedTokens)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    // Energy estimate
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text(formattedEnergy)
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            // Time ago
            Text(timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    private var projectName: String {
        if let path = session.projectPath {
            let components = path.split(separator: "/")
            return String(components.last ?? "Unknown Project")
        }
        return "Unknown Project"
    }

    private var formattedTokens: String {
        let tokens = session.totalTokens
        if tokens >= 1_000_000 {
            return String(format: "%.1fM tokens", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.1fk tokens", Double(tokens) / 1_000.0)
        } else {
            return "\(tokens) tokens"
        }
    }

    private var formattedEnergy: String {
        return String(format: "%.2f Wh", energyEstimate.energyWh)
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(session.lastActivityTime)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
