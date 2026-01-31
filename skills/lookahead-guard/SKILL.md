---
name: lookahead-guard
description: Use when writing or reviewing any indicator, signal, or strategy code to detect future data access, close-price peeking during bar formation, and improper array indexing
---

<!-- TOKEN BUDGET: 380 lines / ~1140 tokens -->

# Lookahead Bias Guard

<activation>

## When This Skill Activates

- Any indicator, signal, or strategy code being written or reviewed
- Files matching: `*.pine`, `*.cs` (NinjaScript), `*_test.go`, `*.go`, `*.py`, `*.js` in indicator/strategy paths
- Builder agent writing indicator or bot code
- Reviewer agent reviewing indicator or bot code
- Plan tasks involving indicator math or signal logic

## Natural Language Triggers
- "indicator", "signal", "strategy code", "entry logic", "exit logic", "bar data", "close price", "lookahead"

</activation>

## Overview

Lookahead bias is the most common and devastating bug in trading systems. It occurs when code accesses data that wouldn't be available at the time the decision is made — using the close price before the bar closes, referencing future bars, or indexing into data that hasn't arrived yet.

**Core principle:** At any point in time, you can only use data from completed bars and the current tick. The current bar's close price is NOT available until the bar closes.

**A single lookahead bug invalidates an entire backtest.** Every profitable signal could be a phantom.

<instructions>

## The Checklist

Run this checklist on EVERY indicator, signal, or strategy code change:

### 1. Close Price During Formation

The current bar's `close` is NOT the final close — it's the last tick received. Using it as if it were final is lookahead.

| Platform | Dangerous | Safe |
|----------|-----------|------|
| **Pine Script** | `close` (during bar formation) | `close[1]` (previous completed bar) |
| **Pine Script** | `ta.ema(close, 20)` on current bar | `ta.ema(close, 20)[1]` or use `barstate.isconfirmed` |
| **NinjaScript** | `Close[0]` in `OnBarUpdate()` | `Close[0]` in `OnBarClose()` only, or `Close[1]` |
| **Go** | `bars[len(bars)-1].Close` during streaming | `bars[len(bars)-2].Close` or wait for bar close event |
| **Python** | `df['close'].iloc[-1]` during live | `df['close'].iloc[-2]` or confirmed bar flag |

**Key rule:** If the code runs on every tick (not just bar close), `close` / `Close[0]` / `bars[last]` is the CURRENT tick, not the bar's final value.

### 2. Future Bar Access

Code must never access bars that haven't occurred yet.

| Platform | Dangerous | Why |
|----------|-----------|-----|
| **Pine Script** | `close[−1]` (future bar) | Negative index = future data |
| **Go** | `bars[i+1]` in a loop | Next bar doesn't exist at time `i` |
| **Python** | `df['close'].shift(-1)` | Shift with negative = future data |
| **NinjaScript** | `Close[−1]` or accessing `BarsAgo < 0` | Negative BarsAgo = future |

### 3. Improper Array Indexing

Off-by-one errors that accidentally include the current (unconfirmed) bar.

| Pattern | Problem | Fix |
|---------|---------|-----|
| `for i := 0; i < len(bars); i++` | Includes current forming bar | `for i := 0; i < len(bars)-1; i++` |
| `bars[0]` as "oldest" | Ambiguous — is index 0 oldest or newest? | Document convention; verify direction |
| `Series[0]` in NinjaScript | Current bar (may be forming) | Use `Series[1]` for confirmed, or ensure `Calculate = OnBarClose` |
| `df.iloc[-1]` in pandas | Last row may be incomplete | Check if last bar is confirmed before using |

### 4. Indicator Warm-up Period

Indicators need N bars of history before producing valid output. Using them before warm-up is a form of lookahead (the value is meaningless but appears valid).

| Indicator | Minimum Bars Needed |
|-----------|-------------------|
| SMA(N) | N bars |
| EMA(N) | ~3*N bars for convergence |
| ATR(N) | N+1 bars |
| Bollinger(N) | N bars |
| MACD(12,26,9) | 26+9 = 35 bars minimum |

**Check:** Does the code guard against using indicator values during warm-up?

### 5. Session Boundary Leakage

Using data from the previous session as if it's part of the current session.

| Pattern | Problem |
|---------|---------|
| Overnight high/low carried into RTH | Previous session data treated as current |
| VWAP not resetting at session start | Cumulative value includes wrong session |
| Volume profile spanning sessions | Mixed session data |

</instructions>

<rules>

## Red Flags — STOP and Investigate

If you see ANY of these patterns, flag them immediately:

- `close` or `Close[0]` used in signal logic without `barstate.isconfirmed` or `OnBarClose` guard
- Negative array indices or negative `shift()` values on price data
- Loop iterating to `len(bars)` instead of `len(bars)-1`
- Indicator values used on bar 0 without warm-up check
- Backtest results that are "too good" (Sharpe > 3, win rate > 75%) — likely lookahead
- Any data access pattern where you can't answer: "Would this value be available at this exact moment in real-time?"

## The Acid Test

For every data access in signal/strategy code, ask:

> **"If I were watching this bar form tick-by-tick in real time, would I have this exact value at the moment the code executes?"**

If the answer is "no" or "I'm not sure" — it's lookahead. Fix it.

## Platform-Specific Defaults

| Platform | Default Execution | Safe for `close`? |
|----------|------------------|-------------------|
| Pine Script | On every tick | NO — use `close[1]` or `barstate.isconfirmed` |
| NinjaScript | `Calculate.OnEachTick` | NO — switch to `Calculate = Calculate.OnBarClose` or use `[1]` |
| Go backtest engine | On bar close | YES — but verify engine configuration |
| Python (vectorized) | All bars at once | YES in backtest — but verify no future leakage via `shift(-N)` |

</rules>

<examples>

## Example: Pine Script Lookahead

<example type="bad" title="Using close during bar formation">
```pine
//@version=5
indicator("Bad EMA Cross")
fast = ta.ema(close, 9)
slow = ta.ema(close, 21)
longSignal = ta.crossover(fast, slow)
// BUG: close is the CURRENT tick, not the final bar close
// In backtest, Pine uses final close — creating lookahead bias
// In live, this fires on every tick where fast > slow, then un-fires
```
</example>

<example type="good" title="Using confirmed bar data only">
```pine
//@version=5
indicator("Safe EMA Cross")
fast = ta.ema(close, 9)[1]
slow = ta.ema(close, 21)[1]
longSignal = ta.crossover(fast, slow)
// SAFE: Uses previous bar's confirmed values only
// Behaves identically in backtest and live
```
</example>

## Example: Go Backtest Loop

<example type="bad" title="Including current forming bar">
```go
for i := 0; i < len(bars); i++ {
    signal := ema(bars[:i+1], 20) // includes bars[i] which may be forming
    if signal > bars[i].Close {   // bars[i].Close may not be final
        buy(bars[i])
    }
}
```
</example>

<example type="good" title="Using only completed bars">
```go
for i := 1; i < len(bars); i++ {
    signal := ema(bars[:i], 20)     // only completed bars up to i-1
    if signal > bars[i-1].Close {   // bars[i-1] is confirmed closed
        buy(bars[i])                // execute on next bar open
    }
}
```
</example>

## Example: NinjaScript OnBarUpdate

<example type="bad" title="Using Close[0] with OnEachTick">
```csharp
// Calculate = Calculate.OnEachTick (default)
protected override void OnBarUpdate()
{
    if (Close[0] > EMA(Close, 20)[0])  // Close[0] changes every tick!
        EnterLong();
}
```
</example>

<example type="good" title="Using OnBarClose or confirmed offset">
```csharp
// Option 1: Change calculation mode
Calculate = Calculate.OnBarClose;
protected override void OnBarUpdate()
{
    if (Close[0] > EMA(Close, 20)[0])  // Now safe — only fires on bar close
        EnterLong();
}

// Option 2: Use [1] offset for confirmed data
protected override void OnBarUpdate()
{
    if (Close[1] > EMA(Close, 20)[1])  // Previous confirmed bar
        EnterLong();
}
```
</example>

</examples>

## Integration

**Fires automatically during:** Builder code writing, Reviewer code review, Strategy Verifier verification
**Pairs with:** `quantdev:backtest-integrity` (lookahead often produces suspiciously good results), `quantdev:risk-discipline` (complements risk checks)
