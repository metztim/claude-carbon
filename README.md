# Claude Carbon

A macOS menu bar app that tracks energy consumption and carbon footprint of Claude Code sessions in real-time.

## Features

- **Real-time tracking**: Monitors Claude Code sessions via ~/.claude/history.jsonl
- **Token estimation**: Estimates input/output tokens from prompts using character-based approximation
- **Energy calculation**: Converts token counts to energy consumption (Wh) and carbon emissions (gCO2e)
- **Model support**: Tracks Haiku, Sonnet, and Opus models with different energy coefficients
- **Household comparisons**: Translates abstract metrics into relatable equivalents (e.g., "LED bulb for 10 seconds")
- **Historical tracking**: View session history and cumulative statistics
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

1. **Hook integration**: ClaudeCarbon installs hooks in `~/.claude/settings.json` that trigger on prompt submission
2. **Event capture**: The app receives events via URL scheme (`claudecarbon://event`)
3. **History monitoring**: Monitors `~/.claude/history.jsonl` to read prompt text
4. **Token estimation**: Estimates tokens using character count / 4 (configurable)
5. **Energy calculation**:
   - Tokens × Model J/token × PUE = Energy (J)
   - Energy (J) / 3600 = Energy (Wh)
   - Energy (Wh) × Carbon intensity / 1000 = CO2 (g)
6. **Display**: Shows results in menu bar with household comparisons

For detailed technical documentation, see [METHODOLOGY.md](METHODOLOGY.md).

## Limitations

- **Token estimation accuracy**: Uses character-based approximation (not true tokenization)
- **Energy coefficient uncertainty**: Model-specific values are inferred or research-based (see confidence levels)
- **Output token estimation**: Uses a 2.5× multiplier which may vary by use case
- **No API access**: Cannot read actual token counts from Anthropic API
- **Single model tracking**: Assumes consistent model use within sessions

These limitations are documented transparently in the methodology. We welcome contributions to improve accuracy.

## Contributing

Contributions are welcome, especially:

- **Better energy coefficients**: Share research or measured data on Claude model energy consumption
- **Token estimation improvements**: Alternative approaches to character-based estimation
- **Infrastructure data**: More accurate PUE and carbon intensity values
- **Feature requests**: Ideas for better visualization or tracking

To contribute:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built as part of the [AI Watchdog](https://github.com/metztim/ai-watchdog) project
- Energy research based on TokenPowerBench 2024 and Epoch AI data
- Carbon intensity data from EPA 2024

## Learn More

- [METHODOLOGY.md](METHODOLOGY.md) - Detailed technical methodology
- [AI Watchdog Project](https://github.com/metztim/ai-watchdog) - Research on AI accountability
