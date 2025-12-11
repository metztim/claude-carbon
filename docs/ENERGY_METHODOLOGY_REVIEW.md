# Energy Calculation Review - Independent Assessment

> **Priority**: High
> **Labels**: methodology, review
> **Date**: 2025-12-11

An independent review of Claude Carbon's energy calculation methodology, examining the scientific basis, sources, and accuracy of the implementation.

---

## Executive Summary

The app implements a **token-to-energy-to-carbon pipeline** that reads actual token counts from Claude's JSONL logs and converts them to energy/carbon estimates. While the methodology is transparent and well-documented, several areas need attention for improved accuracy.

**Overall Assessment:**
- ✅ Transparent methodology with explicit confidence levels
- ✅ Uses actual API token counts (not estimates)
- ⚠️ Energy coefficients are educated guesses without Claude-specific validation
- ⚠️ Some cited sources cannot be verified
- ⚠️ Combined uncertainty is order-of-magnitude (3-10×)

---

## Detailed Findings

### 1. Token Data Source ✅

**Good news**: The implementation reads **actual token counts** from Claude's session logs (`SessionJSONLMonitor.swift:286-287`), not character-based estimates. The methodology doc mentions character-based estimation as a fallback, but the primary path uses real `input_tokens` and `output_tokens` from API responses.

### 2. Energy Coefficients ⚠️

Current values from `Methodology.json`:

| Model | J/token | Confidence | Basis |
|-------|---------|------------|-------|
| Haiku | 0.3 | Low | Pricing ratio inference |
| Sonnet | 1.0 | Medium | "Middle of research range" |
| Opus | 2.0 | Low | Pricing ratio inference |

**Issues:**
- [ ] The Sonnet baseline (1.0 J/token) lacks Claude-specific validation
- [ ] Research on LLM energy varies by orders of magnitude depending on batch size, hardware, quantization
- [ ] Pricing ratios as proxy for energy is creative but imperfect (pricing includes margin, demand, competitive factors)
- [ ] The stated range "0.4-4 J/token" is very wide

**Action items:**
- [ ] Research and cite actual peer-reviewed sources for energy coefficients
- [ ] Consider adding confidence intervals to displayed estimates (e.g., "0.05-0.5 Wh" range)
- [ ] Investigate if Anthropic has published any energy/efficiency data

### 3. Input vs Output Token Energy ⚠️

**Issue**: The code treats input and output tokens identically:
```swift
let totalTokens = inputTokens + outputTokens
let energyJoules = Double(totalTokens) * joulesPerToken * methodology.pue
```

**Research suggests** output generation is 2-5× more energy-intensive per token than input encoding (autoregressive generation vs. parallel encoding).

**Action items:**
- [ ] Research input/output energy differential
- [ ] Consider adding an output token multiplier for energy (not just for estimation)
- [ ] Document decision either way in methodology

### 4. Infrastructure Factors

**PUE (1.2)** ✅
- Appropriate for hyperscale facilities
- Google reports 1.1, AWS 1.15-1.25
- Anthropic likely uses AWS/GCP
- **Confidence: Medium-High**

**Carbon Intensity (384 gCO2e/kWh)** ⚠️
- Uses US national grid average (EPA eGRID 2024)
- **Problem**: Regional variation is significant:
  - AWS us-west-2 (Oregon): ~100-150 gCO2e/kWh (hydro-heavy)
  - AWS us-east-1 (Virginia): ~350-400 gCO2e/kWh
  - GCP us-central1 (Iowa): ~400-450 gCO2e/kWh

**Action items:**
- [ ] Consider adding regional carbon intensity options
- [ ] Research Anthropic's likely data center locations
- [ ] Add user preference for region selection (optional enhancement)

### 5. Source Verification ❌

| Source | Status | Action Needed |
|--------|--------|---------------|
| "TokenPowerBench 2024" | **Cannot verify** - no DOI/URL found | Replace with verifiable citation |
| "Epoch AI" | Verifiable organization | Add specific paper/dataset reference |
| "EPA 2024" | Verifiable (eGRID) | Add direct link to eGRID |
| "Anthropic pricing" | Public data | Document source URL |

**Action items:**
- [ ] Replace "TokenPowerBench 2024" with verifiable primary sources
- [ ] Suggested replacements:
  - Patterson et al. 2021 "Carbon Emissions and Large Neural Network Training"
  - Luccioni et al. 2023 "Power Hungry Processing: Watts Driving the Cost of AI Deployment?"
  - Strubell et al. 2019 "Energy and Policy Considerations for Deep Learning in NLP"
- [ ] Add DOIs or URLs for all citations

### 6. Missing Factors (Documented)

These are acknowledged in METHODOLOGY.md but worth tracking:

- [ ] **Prompt caching** - Claude uses caching for repeated context (reduces compute)
- [ ] **Batch efficiency** - API calls are batched server-side
- [ ] **GPU utilization** - Inference rarely runs at 100%
- [ ] **Networking energy** - Minimal but not zero
- [ ] **Embodied carbon** - Hardware manufacturing (acknowledged as out of scope)
- [ ] **Training amortization** - (acknowledged as out of scope)

---

## Accuracy Assessment

| Component | Uncertainty Range |
|-----------|------------------|
| Token counts | ±5% (actual API data) |
| J/token coefficient | ±50-300% |
| PUE | ±10% |
| Carbon intensity | ±50% (regional) |

**Combined uncertainty**: Order of magnitude (could be 3-10× too high or low)

This aligns with the stated accuracy in METHODOLOGY.md.

---

## Recommendations

### High Priority
1. **Fix source citations** - Replace unverifiable "TokenPowerBench 2024" with real papers
2. **Add confidence intervals** - Show ranges, not just point estimates
3. **Document input/output token decision** - Either weight them differently or explain why not

### Medium Priority
4. **Regional carbon options** - Let users select cloud region
5. **Output token energy weighting** - Research and potentially implement

### Low Priority / Future
6. **Validation study** - Compare against actual measurements if possible
7. **Prompt caching estimation** - Account for cached context

---

## What's Done Well ✅

- **Radical transparency** in METHODOLOGY.md - every assumption documented
- **Confidence levels** explicitly stated for each coefficient
- **Actual token counts** used instead of estimates
- **Limitations section** is honest and comprehensive
- **Household comparisons** make abstract numbers relatable

---

## Files to Review/Update

- `METHODOLOGY.md` - Update sources, add confidence intervals guidance
- `ClaudeCarbon/Resources/Methodology.json` - Update source references
- `ClaudeCarbon/Services/EnergyCalculator.swift` - Consider input/output weighting
- `ClaudeCarbon/Models/EnergyEstimate.swift` - Consider adding range properties

---

## References for Improvement

Suggested peer-reviewed sources to cite:

1. Patterson, D., et al. (2021). "Carbon Emissions and Large Neural Network Training." arXiv:2104.10350
2. Luccioni, A.S., et al. (2023). "Power Hungry Processing: Watts Driving the Cost of AI Deployment?" arXiv:2311.16863
3. Strubell, E., et al. (2019). "Energy and Policy Considerations for Deep Learning in NLP." ACL 2019
4. Dodge, J., et al. (2022). "Measuring the Carbon Intensity of AI in Cloud Instances." FAccT 2022
5. EPA eGRID: https://www.epa.gov/egrid

---

## How to Create GitHub Issue

To create this as a GitHub issue, run:

```bash
gh issue create \
  --title "[Review] Energy Calculation Methodology Audit - Independent Assessment" \
  --label "priority:high,methodology,review" \
  --body-file docs/ENERGY_METHODOLOGY_REVIEW.md
```
