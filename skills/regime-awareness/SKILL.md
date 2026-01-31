---
name: regime-awareness
description: Use when designing strategies, analyzing backtest results, or running optimizations to ensure regime context is considered and single-regime dependency is flagged
---

<!-- TOKEN BUDGET: 320 lines / ~960 tokens -->

# Regime Awareness

<activation>

## When This Skill Activates

- Strategy design discussions and entry/exit logic design
- Backtest result analysis and interpretation
- Optimization runs and parameter sweeps
- Strategy Architect designing new strategies
- Quant Researcher analyzing market behavior
- Any mention of strategy performance without regime context

## Natural Language Triggers
- "strategy design", "backtest results", "optimization", "parameter sweep", "this strategy works", "profitable strategy", "strategy performance"

</activation>

## Overview

Markets cycle through distinct regimes. A strategy that prints money in a trending market will bleed in a range. Ignoring regimes is the #1 cause of strategy failure in live trading after promising backtests.

**Core principle:** Every strategy has a regime it thrives in and a regime it dies in. If you don't know both, you don't understand your strategy.

<instructions>

## The Four Regimes

| Regime | Characteristics | Typical Indicators | Good For | Bad For |
|--------|-----------------|-------------------|----------|---------|
| **Trending** | Strong directional moves, higher highs/lows (up) or lower highs/lows (down) | ADX > 25, EMA slope steep, price above/below all MAs | Trend-following, breakout, momentum | Mean-reversion, fade |
| **Ranging** | Price oscillates between support/resistance, mean-reverting | ADX < 20, Bollinger bandwidth narrow, price crossing MAs frequently | Mean-reversion, fade, range-bound | Trend-following, breakout |
| **Volatile** | Wide swings in both directions, no clear trend | ATR expanding, Bollinger bandwidth wide, VIX elevated | Volatility strategies, options | Tight stops get hunted, small position sizes |
| **Low-Volatility** | Compression, tight range, breakout pending | Bollinger squeeze, ATR contracting, volume declining | Breakout anticipation, straddles | Most strategies (no movement = no profit) |

## Regime Detection Filters

### ADX (Average Directional Index)
- ADX > 25: Trending (direction from +DI/-DI)
- ADX < 20: Ranging or low-volatility
- ADX rising: Trend strengthening
- ADX falling: Trend weakening

### Bollinger Bandwidth
- Bandwidth expanding: Volatility increasing
- Bandwidth contracting: Squeeze forming, breakout imminent
- Bandwidth > 2x 20-period average: High volatility regime
- Bandwidth < 0.5x 20-period average: Low volatility regime

### ATR (Average True Range)
- ATR > 1.5x 20-period average: Volatile regime
- ATR < 0.5x 20-period average: Low-volatility regime
- ATR expanding: Transition from calm to volatile
- ATR contracting: Transition from volatile to calm

## Backtest Segmentation Protocol

When analyzing ANY backtest result, segment by regime:

### Step 1: Classify Each Trading Day

```
For each day in the backtest period:
  1. Calculate ADX(14) value
  2. Calculate Bollinger Bandwidth(20, 2)
  3. Calculate ATR(14) relative to 20-day average ATR
  4. Classify: trending / ranging / volatile / low-vol
```

### Step 2: Compute Per-Regime Metrics

For each regime, compute independently:
- Profit factor
- Sharpe ratio
- Win rate
- Average win/loss ratio
- Max drawdown
- Trade count

### Step 3: Flag Single-Regime Dependency

**WARNING triggers:**
- > 80% of profits come from one regime
- Strategy loses money in 2+ regimes
- < 10 trades in any regime (insufficient sample)
- Sharpe varies by > 1.0 across regimes

### Step 4: Recommend Regime Filters

If strategy is regime-dependent, suggest adding a filter:

| Strategy Type | Suggested Filter | Implementation |
|--------------|-----------------|----------------|
| Trend-following | ADX > 25 gate | Only enter when ADX(14) > 25 |
| Mean-reversion | ADX < 20 gate | Only enter when ADX(14) < 20 |
| Breakout | Bollinger squeeze | Only enter when bandwidth < threshold |
| Volatility | ATR expansion | Only enter when ATR > 1.5x average |

</instructions>

<rules>

## Mandatory Questions

When a strategy is presented without regime context, ask:

1. **"Which regime does this strategy target?"** — If the answer is "all of them," the strategy is almost certainly overfitted.
2. **"What happens to this strategy in a ranging market?"** (if trend-following) or **"What happens in a strong trend?"** (if mean-reversion)
3. **"Have you segmented your backtest results by regime?"** — If no, the aggregate metrics are misleading.

## Red Flags — STOP and Investigate

- Backtest shows consistent profits across ALL regimes — almost certainly overfitted or lookahead
- Strategy has no regime filter and "works in all conditions" — too good to be true
- Optimization found "one perfect parameter set" — likely curve-fitted to a single regime
- Equity curve is smooth through known regime transitions (e.g., 2020 COVID crash, 2022 rate hikes)
- Strategy description doesn't mention which market conditions it targets

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| "Universal strategy" | No strategy works everywhere | Define target regime explicitly |
| Aggregate Sharpe only | Hides regime-specific losses | Segment by regime |
| Optimizing across full dataset | Mixes regimes in optimization | Optimize per-regime or use walk-forward |
| No regime filter | Strategy enters in hostile regimes | Add ADX/ATR/bandwidth gate |
| Backtesting only bull market | Survivorship bias in regime | Include bear/range/volatile periods |

</rules>

<examples>

## Example: Regime-Segmented Analysis

<example type="good" title="Segmented backtest with regime awareness">
```
Strategy: Keltner Channel Breakout (ES futures, 2020-2024)

Overall:  PF 2.1  |  Sharpe 1.4  |  Win 52%  |  342 trades

By Regime:
  Trending:    PF 3.8  |  Sharpe 2.3  |  Win 61%  |  142 trades  <-- Sweet spot
  Ranging:     PF 0.7  |  Sharpe -0.4 |  Win 38%  |  108 trades  <-- Losing money
  Volatile:    PF 1.3  |  Sharpe 0.5  |  Win 48%  |  72 trades   <-- Marginal
  Low-Vol:     PF 1.1  |  Sharpe 0.2  |  Win 45%  |  20 trades   <-- Insufficient sample

RECOMMENDATION: Add ADX(14) > 25 filter to avoid ranging markets.
With filter:   PF 3.2  |  Sharpe 2.0  |  Win 58%  |  214 trades
```
Clear regime segmentation reveals the strategy is a trend-follower that bleeds in ranges.
</example>

<example type="bad" title="Aggregate-only analysis hiding regime dependency">
```
Strategy: Keltner Channel Breakout (ES futures, 2020-2024)

Results:  PF 2.1  |  Sharpe 1.4  |  Win 52%  |  342 trades

CONCLUSION: Strategy is profitable. Ready to deploy.
```
Hides the fact that 90% of profits come from trending periods and the strategy loses money in ranges.
</example>

</examples>

## Integration

**Fires automatically during:** Strategy Architect design, Backtester analysis, Optimizer parameter sweeps
**Pairs with:** `quantdev:backtest-integrity` (regime-unaware results are suspect), `quantdev:risk-discipline` (regime transitions increase risk)
