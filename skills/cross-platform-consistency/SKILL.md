---
name: cross-platform-consistency
description: Use when any indicator code changes on any platform to remind about cross-platform validation and flag potential drift between implementations
---

<!-- TOKEN BUDGET: 260 lines / ~780 tokens -->

# Cross-Platform Consistency

<activation>

## When This Skill Activates

- Any indicator code change on any platform
- Files matching: `*.pine`, `*.cs` (in indicator paths), `*.go` (indicator packages), `*.py` (indicator modules), `*.js` (Tradovate indicators)
- After completing an indicator implementation or port
- When discussing indicator math differences across platforms

## Natural Language Triggers
- "port indicator", "convert to Pine", "NinjaScript version", "cross-platform", "validate indicator", "indicator drift", "values don't match"

</activation>

## Overview

When the same indicator exists on multiple platforms, implementations can drift. A Keltner Channel in Go might use a different ATR calculation than the Pine Script version. These subtle differences cause signal divergence — your backtest says "buy" but your chart says "hold."

**Core principle:** One indicator, one math, every platform. Drift is a silent strategy killer.

<instructions>

## Platform Tier Reference

| Tier | Platforms | Role |
|------|-----------|------|
| **Tier 1** | Go, Python | Source of truth for math. Backtest engine. |
| **Tier 2** | Pine Script | Primary charting platform. Most indicators live here. |
| **Tier 3** | NinjaScript C#, Tradovate JS | Port when needed. Secondary priority. |

**Rule:** Tier 1 implementations define the correct math. Other tiers must match.

## When Indicator Code Changes

### Step 1: Identify Affected Platforms

When an indicator file is modified, check which other platforms have the same indicator:

```
Indicator modified: indicators/keltner/keltner.go

Check for siblings:
  indicators/keltner/keltner.pine     -- exists? YES
  indicators/keltner/keltner.cs       -- exists? NO
  indicators/keltner/keltner.py       -- exists? YES
  indicators/keltner/keltner.js       -- exists? NO

Affected platforms: Go (modified), Pine Script, Python
```

### Step 2: Remind About Validation

After any indicator code change, remind:

```
CROSS-PLATFORM CHECK: You modified keltner.go.
This indicator also exists on: Pine Script, Python

Run /quantdev:validate keltner to verify all implementations still match.
```

### Step 3: Flag Potential Drift Sources

These changes are high-risk for causing drift:

| Change Type | Risk | Example |
|-------------|------|---------|
| Math formula change | CRITICAL | Changing ATR calculation method |
| Period/length change | HIGH | Changing default EMA period |
| Rounding behavior | MEDIUM | Float precision differences |
| Edge case handling | MEDIUM | What happens when bars < period |
| Input validation | LOW | Rejecting invalid parameters |

## Common Drift Sources

### EMA Calculation Variants

| Platform | Default EMA | Difference |
|----------|-------------|-----------|
| Pine Script | RMA-based (Wilder's) for some built-ins | Different smoothing factor |
| NinjaScript | Standard EMA | `2/(N+1)` multiplier |
| Go/Python | Implementation-dependent | Must match chosen reference |

**Fix:** Document which EMA variant is the reference. All platforms must use the same formula.

### ATR Calculation Variants

| Variant | Formula | Used By |
|---------|---------|---------|
| Wilder's ATR | RMA of true range | Pine Script `ta.atr()` default |
| Standard ATR | SMA of true range | Some NinjaScript implementations |

**Fix:** Explicitly choose one variant. Document it. Enforce across platforms.

### Session Handling

| Platform | Default Session | Impact |
|----------|----------------|--------|
| Pine Script | Exchange default | May include overnight |
| NinjaScript | Instrument session template | Configurable |
| Go backtest | Data file determines | Depends on data source |

**Fix:** Align session definitions across platforms. Use ET times from config.

## Golden File Validation

Golden files in `.quantdev/validation/golden/` provide the reference:

```
.quantdev/validation/golden/
  keltner/
    input.csv          # Identical input data for all platforms
    expected.csv       # Expected output (from Tier 1 implementation)
    tolerance.json     # Per-field epsilon values
```

### Tolerance Guidelines

| Field Type | Typical Epsilon | Rationale |
|------------|----------------|-----------|
| Price values | 0.01 | Tick size for futures |
| Indicator values | 0.0001 | Float precision across languages |
| Signal (boolean) | 0 (exact) | Signals must match exactly |
| Volume | 0 (exact) | Integer values, must match |

</instructions>

<rules>

## Red Flags — STOP and Investigate

- Indicator values differ by > epsilon between platforms on the same input data
- Signal fires on one platform but not another for the same bar
- One platform shows a crossover that another doesn't
- Backtest results differ significantly when running same strategy on Go vs Python
- Chart (Pine Script) shows different indicator values than backtest engine (Go)

## Mandatory Actions

1. **After ANY indicator code change:** Remind user to run `/quantdev:validate`
2. **After porting to a new platform:** Run validation before considering the port complete
3. **Before any backtest:** Verify indicator implementations match across platforms used
4. **When debugging signal mismatch:** Check cross-platform consistency FIRST

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| "I'll validate later" | Drift compounds over time | Validate immediately after change |
| "It's just a minor tweak" | Minor tweaks cause signal divergence | ALL changes need validation |
| "Pine Script is close enough" | "Close enough" means different signals | Must be within epsilon |
| "I tested on one platform" | Other platforms may have drifted | Test ALL affected platforms |

</rules>

<examples>

## Example: Detecting Drift

<example type="good" title="Catching drift after a change">
```
Modified: indicators/supertrend/supertrend.go
  Changed ATR period from 10 to 14

Cross-platform check:
  supertrend.pine  -- uses ta.atr(10) -- OUTDATED, needs update
  supertrend.py    -- uses atr(period=10) -- OUTDATED, needs update

Action: Updated all platforms to ATR period 14.
Ran /quantdev:validate supertrend -- all platforms match within epsilon.
```
</example>

<example type="bad" title="Changing one platform without checking others">
```
Modified: indicators/supertrend/supertrend.go
  Changed ATR period from 10 to 14

Committed and moved on.

Result: Go backtest now uses ATR(14), Pine Script chart still shows ATR(10).
Signals diverge. Live trades don't match what the chart shows.
```
</example>

</examples>

## Integration

**Fires automatically during:** Builder indicator changes, Reviewer indicator review
**Pairs with:** `quantdev:lookahead-guard` (both are indicator correctness checks), `/quantdev:validate` command (this skill reminds to run it)
