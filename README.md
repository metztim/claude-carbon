# Claude Carbon

A macOS menu bar app that tracks energy consumption and carbon footprint of Claude Code sessions in real-time.

## Why?

AI usage has an environmental cost. Every API call consumes energy and generates carbon emissions. Most people have no visibility into this impact.

Claude Carbon makes the invisible visible - translating your token usage into relatable equivalents like "laptop running for 6 hours" or "phone charges." The goal isn't to shame you into using AI less, but to help you make informed choices (like using Haiku for simple tasks instead of Opus).

## Features

- **Accurate token tracking**: Reads actual input/output tokens from Claude Code's session logs
- **Model-aware calculations**: Different energy estimates for Opus, Sonnet, and Haiku
- **Real-time feedback**: Menu bar icon pulses when tokens are being consumed
- **Household comparisons**: Translates abstract metrics into relatable equivalents (LED bulb, phone charge, laptop hours)
- **Historical tracking**: View today, this week, or all-time statistics
- **Transparent methodology**: All calculations are open and documented (see [METHODOLOGY.md](METHODOLOGY.md))

## Installation

### Option 1: Download Pre-built App

1. Download the latest release from [Releases](https://github.com/metztim/claude-carbon/releases)
2. Move `ClaudeCarbon.app` to your Applications folder
3. Run the installation script to enable tracking:
   ```bash
   cd /path/to/Scripts
   ./install-hooks.sh
   ```
4. Restart Claude Code
5. Launch ClaudeCarbon from Applications

### Option 2: Build from Source

1. Clone this repository:
   ```bash
   git clone https://github.com/metztim/claude-carbon.git
   cd claude-carbon
   ```

2. Open `ClaudeCarbon.xcodeproj` in Xcode

3. Build and run (⌘R)

4. Install tracking hooks:
   ```bash
   ./Scripts/install-hooks.sh
   ```

5. Restart Claude Code

### Installation Script Details

The `install-hooks.sh` script adds event hooks to `~/.claude/settings.json` that notify ClaudeCarbon when prompts are submitted. The hooks use the `claudecarbon://` URL scheme to send events to the app.

Requirements:
- `jq` (for automatic installation): `brew install jq`
- If jq is not available, the script provides manual installation instructions

## Usage

1. **Launch the app**: ClaudeCarbon runs in your menu bar with a leaf icon
2. **Start using Claude Code**: The app automatically tracks new sessions
3. **View statistics**: Click the menu bar icon to see:
   - Current session energy and carbon
   - Total cumulative statistics
   - Household comparisons
   - Recent session history

### Menu Bar Display

The menu bar shows real-time statistics:
- Energy consumption in Wh
- Carbon emissions in grams CO2e
- Relatable household comparisons (e.g., "LED bulb for 30 seconds")
- Session-by-session breakdown

### Screenshots

*(Menu bar interface showing energy statistics)*

*(Settings panel with methodology configuration)*

## Configuration

Access settings by clicking the gear icon in the menu bar dropdown.

**Available settings:**
- **Model selection**: Choose which Claude model to track (Haiku, Sonnet, Opus)
- **Methodology values**: Customize energy coefficients (advanced users)
- **Reset data**: Clear session history

The app uses a JSON-based methodology file (`Methodology.json`) that can be customized for more accurate estimates. See [METHODOLOGY.md](METHODOLOGY.md) for details.

## How It Works

1. **Session monitoring**: Watches `~/.claude/history.jsonl` for new Claude Code sessions
2. **Token tracking**: Reads actual token counts from `~/.claude/projects/{path}/{session}.jsonl`
3. **Energy calculation**:
   - Tokens × Model-specific J/token × PUE = Energy (J)
   - Energy (J) / 3600 = Energy (Wh)
   - Energy (Wh) × Carbon intensity / 1000 = CO2 (g)
4. **Display**: Shows results in menu bar with household comparisons

For detailed technical documentation, see [METHODOLOGY.md](METHODOLOGY.md).

## Limitations

- **Energy coefficient uncertainty**: Model-specific J/token values are inferred from pricing ratios (see confidence levels in methodology)
- **US grid average**: Carbon intensity uses EPA 2024 data for US average (384 gCO2/kWh)
- **Claude Code only**: Currently tracks CLI usage; Claude web/desktop app integration is planned

These limitations are documented transparently. Contributions to improve accuracy are welcome.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where help is especially appreciated:
- **Methodology improvements**: Better J/token estimates, regional carbon intensity
- **Gamification**: Personal bests, achievements, efficiency scores
- **Research**: AI energy consumption data and sources

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built as part of the [AI Watchdog](https://github.com/metztim/ai-watchdog) project
- Energy research based on TokenPowerBench 2024 and Epoch AI data
- Carbon intensity data from EPA 2024

## Learn More

- [METHODOLOGY.md](METHODOLOGY.md) - Detailed technical methodology
- [AI Watchdog Project](https://github.com/metztim/ai-watchdog) - Research on AI accountability
