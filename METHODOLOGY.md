# Energy Estimation Methodology

This document provides a transparent, detailed explanation of how ClaudeCarbon estimates energy consumption and carbon emissions from Claude Code usage.

## Why We Built This

AI energy consumption is invisible to users. Running a single Claude Code session can consume as much energy as running a laptop for minutes, but without measurement, there's no awareness or accountability.

ClaudeCarbon makes AI energy visible by:
1. Tracking Claude Code sessions in real-time
2. Estimating token usage from prompts
3. Converting tokens to energy and carbon using research-based coefficients
4. Translating abstract metrics into household comparisons

Our goal is transparency, not precision. We clearly state our assumptions, confidence levels, and limitations.

## Token Estimation Approach

Since ClaudeCarbon doesn't have access to Anthropic's API, we estimate token counts from prompt text.

### Character-Based Estimation

**Method**: Divide character count by average characters per token

```
Estimated tokens = Character count / 4
```

**Rationale**:
- Anthropic's tokenizer (based on Claude's vocabulary) averages ~4 characters per token for English text
- This is approximate—actual values range from 1-10+ depending on text type (code, prose, special characters)
- Minimum of 1 token for any non-empty prompt

**Configuration**: `charsPerToken = 4` (see `Methodology.json`)

### Output Token Multiplier

**Method**: Estimate output tokens as a multiple of input tokens

```
Estimated output tokens = Input tokens × 4.0
```

**Rationale**:
- Claude Code typically generates longer responses than prompts (code, explanations, examples)
- Observed Claude Code sessions show 2-4× more output than input on average
- Output generation is computationally more expensive than input processing (not reflected in token multiplier, but noted for methodology transparency)

**Configuration**: `outputMultiplier = 4.0` (see `Methodology.json`)

### Limitations

- **Not true tokenization**: We don't use Claude's actual tokenizer, so estimates will differ from real token counts
- **Language variation**: Non-English text may have different chars/token ratios
- **Code vs. prose**: Code often has more tokens per character than natural language
- **Context window**: We don't account for context tokens (previous conversation history)

**Accuracy estimate**: ±30-50% for typical use cases

We accept this uncertainty as a trade-off for simplicity and zero API dependencies.

## Energy Coefficients

Energy per token values are based on published research and pricing ratios.

### Model Energy Table

| Model | J/token | Confidence | Rationale |
|-------|---------|------------|-----------|
| **Claude Haiku** | 0.3 | Low | Inferred from pricing ratio relative to Sonnet (pricing ≈ 3:1) |
| **Claude Sonnet** | 1.0 | Medium | Middle of research range (0.4-4 J/token for similar-scale LLMs) |
| **Claude Opus** | 2.0 | Low | Inferred from pricing ratio relative to Sonnet (pricing ≈ 2:1) |

### Confidence Levels Explained

- **High**: Direct measurement or peer-reviewed research specific to Claude models
- **Medium**: Research-based estimates from similar-scale models or industry benchmarks
- **Low**: Inferred from proxy metrics (pricing ratios, architecture comparisons)

**Why we use pricing ratios**: Anthropic's pricing typically correlates with compute costs, including energy. While not perfect, pricing ratios provide a reasonable approximation when direct energy data is unavailable.

### Research Context

Published research on LLM energy consumption shows wide variation:
- Small models (e.g., GPT-2): ~0.1-0.4 J/token
- Medium models (e.g., GPT-3, Claude Sonnet scale): ~0.4-4 J/token
- Large models (e.g., GPT-4, Claude Opus scale): ~2-8 J/token

We use conservative mid-range estimates. If you have better data, [please contribute](#contributing-better-data).

## Infrastructure Factors

Energy coefficients account for model inference only. Infrastructure overhead is added separately.

### Power Usage Effectiveness (PUE)

**Value**: 1.2

**Definition**: Ratio of total data center energy to IT equipment energy

```
Total DC energy = IT equipment energy × PUE
```

**Rationale**:
- Modern hyperscale data centers (AWS, Google, Azure) average PUE 1.1-1.3
- Anthropic likely uses similar facilities
- 1.2 is industry best practice for efficient DCs

**Confidence**: Medium (based on industry benchmarks)

### Carbon Intensity

**Value**: 384 gCO2e/kWh

**Definition**: Grams of CO2-equivalent emissions per kilowatt-hour of electricity

**Rationale**:
- US grid average for 2024 (EPA data)
- Anthropic's primary data centers are in the US
- Does not account for renewable energy purchases (which would lower emissions)

**Confidence**: High (official EPA data)

**Regional variation**: Actual carbon intensity varies by location:
- Renewable-heavy grids (e.g., Pacific Northwest): ~100-200 gCO2e/kWh
- Coal-heavy grids (e.g., Midwest): ~600-800 gCO2e/kWh
- We use national average as a reasonable middle ground

## Calculation Formulas

### Energy Consumption (Wh)

```
Energy (Joules) = Total tokens × J/token × PUE
Energy (Wh) = Energy (Joules) / 3600
```

**Example** (100-token prompt, Sonnet, 4.0× output multiplier):
```
Total tokens = 100 + (100 × 4.0) = 500 tokens
Energy (J) = 500 × 1.0 × 1.2 = 600 J
Energy (Wh) = 600 / 3600 = 0.167 Wh
```

### Carbon Emissions (gCO2e)

```
Carbon (g) = Energy (Wh) × Carbon intensity (gCO2e/kWh) / 1000
```

**Example** (continuing from above):
```
Carbon = 0.167 × 384 / 1000 = 0.064 gCO2e
```

### Combined Formula

```
Carbon (g) = (Tokens × J/token × PUE / 3600) × (Carbon intensity / 1000)
```

## Household Comparison Methodology

Abstract energy numbers are hard to grasp. We convert Wh values to relatable household equivalents.

### Comparison Thresholds

| Energy (Wh) | Equivalent |
|-------------|------------|
| 0.01 | LED bulb for 1 second |
| 0.1 | LED bulb for 10 seconds |
| 1.0 | Charging phone 0.05% |
| 10.0 | Laptop running for 30 seconds |
| 100.0 | Charging phone 5% |
| 1000.0 | Running microwave for 1 minute |

**Basis for comparisons**:
- LED bulb: 10W bulb
- Phone charging: 20 Wh for full charge (0-100%)
- Laptop: 60W typical power draw
- Microwave: 1000W typical power

**Selection logic**: The app shows the largest comparison that's smaller than the actual energy consumption.

## Limitations and Caveats

We believe in radical transparency about what we don't know.

### Known Limitations

1. **Token estimation accuracy**: ±30-50% error due to character-based approximation
2. **Energy coefficient uncertainty**:
   - Haiku and Opus values are inferred from pricing (Low confidence)
   - Sonnet value is research-based but not Claude-specific (Medium confidence)
3. **No caching accounting**: Doesn't track prompt caching, which reduces energy for repeated context
4. **Output multiplier**: 4.0× is an average—your usage may vary (1.5-4× observed)
5. **Infrastructure assumptions**: PUE and carbon intensity are industry averages, not Anthropic-specific
6. **No lifecycle emissions**: Only operational energy, not embodied carbon in hardware
7. **No training costs**: Only inference, not the energy to train models

### What We Don't Include

**Excluded from calculations**:
- Model training energy (one-time cost, amortized over billions of inferences)
- Hardware manufacturing embodied carbon
- Networking energy (data transfer between client and server)
- Claude Code client-side processing

**Why**: These are either negligible per-session or impossible to estimate without Anthropic-specific data.

### Accuracy Statement

These estimates are **educational approximations**, not precise measurements.

**Expected accuracy**:
- Order of magnitude: High confidence (within 2-5×)
- Relative comparisons: Medium confidence (Opus > Sonnet > Haiku is reliable)
- Absolute values: Low confidence (could be 2× too high or 2× too low)

Use these estimates to:
- Build awareness of AI energy consumption
- Compare relative impact of different usage patterns
- Inform decisions about model selection

Do not use for:
- Carbon offset purchases (not precise enough)
- Regulatory compliance reporting
- Scientific research (without validation)

## Sources

Our methodology is based on publicly available research and data:

1. **TokenPowerBench 2024**: Academic benchmark of LLM energy consumption across models
   - Published energy ranges for GPT-3, LLaMA, and similar-scale models
   - Methodology for measuring inference energy

2. **Epoch AI**: AI training compute and energy research
   - Industry benchmarks for data center efficiency
   - Model architecture and scale comparisons

3. **EPA 2024**: US electricity carbon intensity data
   - eGRID database (Emissions & Generation Resource Integrated Database)
   - National and regional average carbon intensities

4. **Anthropic pricing data**: Publicly available API pricing
   - Used as proxy for relative compute costs between models

## Contributing Better Data

We want to improve accuracy. You can help by contributing:

### 1. Better Energy Coefficients

If you have:
- Measured energy data from Claude API usage
- Internal Anthropic documentation (if publicly shareable)
- Research papers with Claude-specific measurements

**How to contribute**: Open an issue or PR with:
- The data/measurement
- Methodology used
- Confidence level and error bars
- Source/citation

### 2. Improved Token Estimation

Alternative approaches:
- Integration with actual tokenizer libraries
- Better chars/token ratios for different content types (code, prose, etc.)
- Dynamic output multipliers based on prompt analysis

### 3. Infrastructure Data

More accurate values for:
- Anthropic's actual PUE (if publicly available)
- Regional carbon intensity if DC locations are known
- Renewable energy percentage in Anthropic's supply

### 4. Validation Studies

Help us validate estimates:
- Compare ClaudeCarbon estimates to API-reported token counts
- Measure correlation between estimated and real energy usage
- Share real-world usage patterns for output multiplier calibration

## Version History

- **v1.0** (2025-01-01): Initial methodology
  - Character-based token estimation (4 chars/token)
  - Research-based energy coefficients (Haiku: 0.3, Sonnet: 1.0, Opus: 2.0 J/token)
  - US grid average carbon intensity (384 gCO2e/kWh)
  - Modern DC PUE (1.2)

## Contact

Questions about methodology? Open an issue on GitHub or contact the maintainer.

For the AI Watchdog project: [https://github.com/yourusername/ai-watchdog](https://github.com/yourusername/ai-watchdog)
