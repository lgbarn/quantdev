---
name: risk-discipline
description: Use when writing bot code, position sizing logic, order execution code, or changing strategy parameters to validate that risk controls are present and properly bounded
---

<!-- TOKEN BUDGET: 340 lines / ~1020 tokens -->

# Risk Discipline

<activation>

## When This Skill Activates

- Bot code being written or modified (entry/exit logic, order management)
- Position sizing logic or calculations
- Order execution code (placing, modifying, canceling orders)
- Strategy parameter changes that affect risk (stop distance, size multiplier)
- Deployment configuration for live or paper trading
- Risk Analyst reviewing strategy risk parameters

## Natural Language Triggers
- "position size", "risk per trade", "stop loss", "max loss", "daily limit", "margin", "leverage", "order size", "risk management"

</activation>

## Overview

Risk discipline is the difference between a bad month and a blown account. Every bot must have bounded risk before it touches a market — even in paper trading. Missing a stop loss on one trade can erase months of profits.

**Core principle:** Every entry must have a defined exit. Every position must have a bounded loss. No exceptions.

<instructions>

## The Risk Checklist

Run this checklist on EVERY bot or strategy code change:

### 1. Per-Trade Risk

Every trade entry MUST have:

- [ ] **Stop loss defined** — A price level or ATR-based distance where the position is exited at a loss
- [ ] **Risk amount calculated** — Dollar amount or percentage at risk on this trade
- [ ] **Risk percentage bounded** — Default max 2% of account per trade; flag anything higher
- [ ] **Stop loss placed with entry** — Stop order submitted simultaneously with entry, not "added later"

```go
// GOOD: Stop placed with entry
entry := Order{Side: Long, Price: currentPrice}
stop := Order{Side: Short, Price: currentPrice - (atr * 2.0), Type: StopMarket}
broker.Submit(entry, stop) // atomic: both or neither

// BAD: Stop "planned" but not placed
entry := Order{Side: Long, Price: currentPrice}
broker.Submit(entry)
// TODO: add stop loss later  <-- THIS WILL KILL YOU
```

### 2. Position Size Limits

Position sizing MUST be bounded:

- [ ] **Maximum position size defined** — Hard cap on contracts/shares per position
- [ ] **Size calculation uses risk amount** — `size = riskAmount / (entryPrice - stopPrice)`, NOT arbitrary
- [ ] **Size cannot exceed account limits** — Respects buying power and margin requirements
- [ ] **Size rounds DOWN** — Always round to smaller size, never up

```go
// GOOD: Risk-based position sizing with bounds
riskPerTrade := account.Balance * 0.01  // 1% risk
stopDistance := atr * 2.0
rawSize := riskPerTrade / stopDistance
size := min(floor(rawSize), maxContracts)  // bounded and rounded down

// BAD: Arbitrary or unbounded sizing
size := 10  // magic number, no risk basis
// or
size := account.Balance / currentPrice  // uses full account, no risk limit
```

### 3. Daily Loss Limit

Every bot MUST have a daily loss circuit breaker:

- [ ] **Max daily loss defined** — Dollar amount or percentage that halts trading for the day
- [ ] **Daily P&L tracked** — Running total of realized + unrealized P&L
- [ ] **Halt mechanism implemented** — Bot stops opening new positions when limit hit
- [ ] **Existing positions handled** — Define behavior: close all, tighten stops, or hold

```go
// GOOD: Daily loss limit with halt
if dailyPnL <= -maxDailyLoss {
    log.Warn("Daily loss limit reached", "pnl", dailyPnL, "limit", maxDailyLoss)
    bot.HaltNewEntries()
    return
}

// BAD: No daily loss tracking
// Bot keeps trading regardless of accumulated losses
```

### 4. Prop Firm Constraints (Apex)

When deploying to Apex accounts, additional constraints apply:

- [ ] **Trailing max drawdown respected** — Apex trailing drawdown from highest equity
- [ ] **Per-account position limits** — Check Apex account tier for max contracts
- [ ] **Daily loss limit ≤ Apex daily limit** — Bot's limit must be stricter than or equal to Apex's
- [ ] **No overnight positions** (unless Apex account allows) — Flatten before session close

### 5. Order Execution Safety

- [ ] **Duplicate order prevention** — Cannot submit entry if already in position
- [ ] **Stale signal rejection** — Signal older than N bars is discarded
- [ ] **Market order slippage budget** — Expected slippage accounted for in risk calculation
- [ ] **Connection loss handling** — What happens if connection drops while in position?

</instructions>

<rules>

## Red Flags — STOP and Investigate

If you see ANY of these in bot code, flag immediately:

| Red Flag | Severity | Action |
|----------|----------|--------|
| Entry without stop loss | CRITICAL | Block deployment. Add stop before proceeding. |
| No daily loss limit | CRITICAL | Block deployment. Add circuit breaker. |
| Position size > 2% risk | HIGH | Require explicit override with rationale. |
| Hardcoded position size | HIGH | Must be calculated from risk parameters. |
| `// TODO: add risk management` | CRITICAL | Not deployed until TODO is resolved. |
| Stop loss in separate function "called later" | HIGH | Must be atomic with entry. |
| No maximum position size cap | HIGH | Add hard cap from account constraints. |
| Risk parameters not in config | MEDIUM | Must be configurable, not hardcoded. |

## Non-Negotiable Rules

1. **Every entry has a stop.** No exceptions. Not "planned," not "coming soon." Placed atomically.
2. **Risk per trade ≤ 2% unless explicitly overridden.** Override requires written rationale.
3. **Daily loss limit exists.** If missing, bot does not deploy — period.
4. **Position size is calculated, not arbitrary.** `size = riskAmount / stopDistance`, bounded by max.
5. **Paper trade first.** No bot goes live without paper trading period showing risk controls work.

## Severity Escalation

| Missing Control | Severity | Deployment? |
|----------------|----------|-------------|
| Stop loss | CRITICAL | BLOCKED |
| Daily loss limit | CRITICAL | BLOCKED |
| Position size bounds | HIGH | BLOCKED |
| Slippage budget | MEDIUM | Allowed with warning |
| Connection loss handling | MEDIUM | Allowed with warning |
| Duplicate order prevention | HIGH | BLOCKED |

</rules>

<examples>

## Example: Properly Risk-Managed Bot

<example type="good" title="Complete risk controls">
```go
type RiskConfig struct {
    MaxRiskPerTrade   float64 `json:"max_risk_per_trade"`   // 0.01 = 1%
    MaxDailyLoss      float64 `json:"max_daily_loss"`       // dollar amount
    MaxContracts      int     `json:"max_contracts"`        // hard cap
    StopATRMultiplier float64 `json:"stop_atr_multiplier"`  // e.g., 2.0
}

func (b *Bot) EnterLong(price, atr float64) error {
    // Check daily loss limit
    if b.dailyPnL <= -b.risk.MaxDailyLoss {
        return ErrDailyLossLimitReached
    }

    // Calculate risk-based position size
    stopPrice := price - (atr * b.risk.StopATRMultiplier)
    stopDistance := price - stopPrice
    riskAmount := b.account.Balance * b.risk.MaxRiskPerTrade
    size := int(math.Floor(riskAmount / stopDistance))
    size = min(size, b.risk.MaxContracts)

    if size <= 0 {
        return ErrPositionTooSmall
    }

    // Submit entry + stop atomically
    return b.broker.SubmitBracket(
        Order{Side: Long, Size: size, Price: price},
        Order{Side: Short, Size: size, Price: stopPrice, Type: StopMarket},
    )
}
```
Every risk control present: daily limit, risk-based sizing, bounded size, atomic stop.
</example>

<example type="bad" title="Missing risk controls">
```go
func (b *Bot) EnterLong(price float64) {
    b.broker.Submit(Order{
        Side: Long,
        Size: 5,          // arbitrary, no risk basis
        Price: price,
    })
    // No stop loss
    // No daily loss check
    // No position size calculation
    // This bot WILL blow up
}
```
</example>

</examples>

## Integration

**Fires automatically during:** Builder bot code, Reviewer bot review, Strategy Verifier verification
**Pairs with:** `quantdev:lookahead-guard` (both are pre-deployment gates), `quantdev:backtest-integrity` (risk parameters affect backtest validity)
