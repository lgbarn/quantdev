---
name: backtest-integrity
description: Use when backtest results are being analyzed or presented to flag overfitting signals, insufficient sample sizes, and missing out-of-sample validation
---

<!-- TOKEN BUDGET: 340 lines / ~1020 tokens -->

# Backtest Integrity

<activation>

## When This Skill Activates

- Backtest results being analyzed, presented, or discussed
- Strategy performance metrics being evaluated
- After any backtest run completes (via PostBacktest hook)
- Optimization results being reviewed
- Before deploying any strategy to paper or live trading

## Natural Language Triggers
- "backtest results", "profit factor", "sharpe ratio", "win rate", "equity curve", "strategy performance", "backtest shows", "results look good"

</activation>

## Overview

Backtests lie. Not because the engine is wrong, but because overfitting, insufficient data, and missing validation create an illusion of profitability. A strategy with a Sharpe of 4.0 on daily data is almost certainly curve-fitted — it found patterns in noise, not signal.

**Core principle:** Be more skeptical of great results than mediocre ones. The better a backtest looks, the harder you should scrutinize it.

<instructions>

## The Red Flag Checklist

Auto-annotate backtest results with confidence warnings when ANY of these are present:

### Metric Red Flags

| Metric | Threshold | Warning | Confidence Impact |
|--------|-----------|---------|-------------------|
| Sharpe Ratio | > 3.0 on daily data | Almost certainly overfitted | CRITICAL |
| Sharpe Ratio | > 2.0 on daily data | Requires strong justification | HIGH |
| Win Rate | > 75% | Suspiciously high — check for lookahead or curve fitting | HIGH |
| Win Rate | > 85% | Almost certainly a bug or overfitting | CRITICAL |
| Profit Factor | > 4.0 | Unrealistic for sustained trading | HIGH |
| Profit Factor | > 6.0 | Almost certainly overfitted or buggy | CRITICAL |
| Max Drawdown | < 5% on multi-year test | Suspiciously low — check data quality | MEDIUM |
| Avg Win / Avg Loss | > 5.0 | Check for outlier dependency | MEDIUM |

### Sample Size Red Flags

| Condition | Warning | Confidence Impact |
|-----------|---------|-------------------|
| < 30 trades total | Statistically meaningless | CRITICAL |
| < 100 trades total | Low confidence in metrics | HIGH |
| < 10 trades per year | Insufficient for annual metrics | HIGH |
| Trades clustered in < 3 months | Sample not representative | HIGH |
| Backtest period < 2 years | Insufficient regime coverage | MEDIUM |

### Validation Red Flags

| Condition | Warning | Confidence Impact |
|-----------|---------|-------------------|
| No out-of-sample (OOS) period defined | Cannot assess generalization | CRITICAL |
| In-sample == full dataset | 100% of data used for fitting | CRITICAL |
| OOS period < 25% of total | Insufficient validation data | HIGH |
| No walk-forward validation | Single split may be lucky | MEDIUM |
| Optimized parameters, no sensitivity test | May be on brittle peak | HIGH |

### Equity Curve Red Flags

| Pattern | Warning | Confidence Impact |
|---------|---------|-------------------|
| Suspiciously smooth curve | Low variance of returns suggests lookahead or curve fitting | HIGH |
| All gains in one period | Strategy may not generalize | HIGH |
| Sharp recovery from drawdowns | Check for survivorship or lookahead | MEDIUM |
| Staircase pattern (long flat, sudden jump) | Dependent on rare events | MEDIUM |

## Annotation Protocol

When backtest results are presented, automatically add annotations:

```
=== BACKTEST INTEGRITY CHECK ===

Results: PF 2.8 | Sharpe 1.6 | Win 58% | 284 trades | 2020-2024

Flags:
  [OK]       Sharpe 1.6 — within plausible range
  [OK]       Win rate 58% — reasonable
  [OK]       284 trades — adequate sample size
  [WARNING]  No out-of-sample period defined — results may not generalize
  [WARNING]  No regime segmentation — see quantdev:regime-awareness

Confidence: MEDIUM (missing OOS validation)
Recommendation: Define OOS holdout (last 25% of data) and re-run
```

## Required Validation Steps

Before any backtest result is considered reliable:

### Step 1: Sample Size Check
- Minimum 30 trades (absolute floor)
- Prefer 100+ trades for statistical significance
- Check trade distribution across time (not clustered)

### Step 2: Out-of-Sample Validation
- Split data: 70% in-sample, 30% out-of-sample
- Train/optimize on in-sample ONLY
- Validate on OOS without changes
- OOS Sharpe should be > 50% of IS Sharpe

### Step 3: Walk-Forward Validation
- Roll the IS/OOS window forward through time
- Train on window 1, test on window 2
- Train on windows 1+2, test on window 3
- All OOS windows should be profitable (or most)

### Step 4: Parameter Sensitivity
- Vary each parameter by +/- 20%
- Strategy should remain profitable across range
- Sharp performance cliffs = brittle optimization
- Prefer parameter plateaus over peaks

### Step 5: Regime Check
- Invoke `quantdev:regime-awareness` for regime segmentation
- Strategy should have positive expectancy in target regime
- Losses in non-target regimes should be bounded

</instructions>

<rules>

## Confidence Ratings

Assign a confidence rating to every backtest result:

| Rating | Criteria |
|--------|----------|
| **HIGH** | 100+ trades, OOS validated, walk-forward passed, regime-segmented, parameter sensitivity clean |
| **MEDIUM** | 30+ trades, some validation done, but missing one of: OOS, walk-forward, regime, or sensitivity |
| **LOW** | < 30 trades, or no OOS, or critical red flags present |
| **INVALID** | Lookahead detected, or in-sample == full dataset with optimization, or < 15 trades |

## Mandatory Annotations

NEVER present backtest results without:
1. Trade count and time period
2. At least one confidence-impacting observation
3. An explicit confidence rating (HIGH/MEDIUM/LOW/INVALID)
4. Recommendation for next validation step

## Red Flags — STOP and Investigate

- Results presented as "ready for live" without OOS validation
- Sharpe > 3.0 on daily data accepted without question
- Win rate > 75% not investigated for lookahead
- < 30 trades used to justify strategy viability
- Parameter optimization on full dataset with no holdout
- "The equity curve looks great" without statistical backing

## The Skepticism Scale

The better the results, the MORE skeptical you should be:

| Result Quality | Required Scrutiny |
|---------------|-------------------|
| Sharpe < 1.0 | Normal review |
| Sharpe 1.0–2.0 | Standard validation (OOS + sensitivity) |
| Sharpe 2.0–3.0 | Deep validation (walk-forward + regime + sensitivity) |
| Sharpe > 3.0 | Assume bug or overfitting until proven otherwise |

</rules>

<examples>

## Example: Properly Validated Backtest

<example type="good" title="Thorough validation with honest assessment">
```
=== Keltner Breakout Strategy — ES Futures ===

In-Sample (2020-2022):
  PF 2.4 | Sharpe 1.8 | Win 55% | 186 trades
  Max DD: -8.2% | Avg Win/Loss: 1.9

Out-of-Sample (2023-2024):
  PF 1.9 | Sharpe 1.3 | Win 52% | 98 trades
  Max DD: -11.4% | Avg Win/Loss: 1.7

Walk-Forward (6-month windows):
  5/6 windows profitable | Worst window: PF 0.8

Parameter Sensitivity (ATR mult 1.5–2.5):
  All profitable | PF range: 1.4–2.4 | Plateau around 2.0

=== INTEGRITY CHECK ===
  [OK] 284 total trades — adequate sample
  [OK] OOS Sharpe (1.3) is 72% of IS Sharpe (1.8) — good generalization
  [OK] Walk-forward: 5/6 windows positive — robust
  [OK] Parameter plateau — not brittle
  [WARNING] OOS max drawdown 39% worse than IS — monitor in live

Confidence: HIGH
Recommendation: Paper trade for 30 days to validate execution assumptions
```
</example>

<example type="bad" title="Unvalidated results presented as conclusive">
```
=== Keltner Breakout Strategy — ES Futures ===

Backtest (2020-2024):
  PF 3.8 | Sharpe 2.9 | Win 68% | 342 trades

CONCLUSION: Excellent strategy. Ready for live deployment.
```
No OOS split, suspiciously high metrics, no sensitivity check, no regime analysis.
This is a sales pitch, not a validation.
</example>

</examples>

## Integration

**Fires automatically via:** PostBacktest hook, Backtester analysis, Strategy Verifier verification
**Pairs with:** `quantdev:regime-awareness` (segment results by regime), `quantdev:lookahead-guard` (great results may indicate lookahead), `quantdev:risk-discipline` (risk parameters affect backtest validity)
