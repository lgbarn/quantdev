---
description: "Trading development dashboard — strategies, backtests, validations, knowledge base"
disable-model-invocation: true
argument-hint: ""
---

# /quantdev:status - Trading Dashboard

You are executing the quantdev status workflow. Follow these steps precisely.

<prerequisites>

## Step 1: Check State Exists

Check if `.quantdev/` directory exists.

- **If it does not exist:**
  Display:
  > "No quantdev project detected in this directory. Run `/quantdev:init` to get started."
  Stop here.

## Step 2: Read State Files

Follow **State Loading Protocol** (read STATE.json, HISTORY.md, PROJECT.md, config.json, and recent artifacts to establish session context; see `docs/PROTOCOLS.md`).

</prerequisites>

<execution>

## Step 3: Display Native Task Progress

Follow **Native Task Scaffolding Protocol** (see `docs/PROTOCOLS.md`) -- call TaskList to show the current state of any quantdev-created native tasks.

## Step 4: Display Trading Dashboard

Present a comprehensive status display:

### Active Strategies

Scan `.quantdev/strategies/` for all strategy directories. For each, report:
```
Active Strategies
═══════════════════════════════════════════

Strategy            Track       State           Last Activity
─────────────────────────────────────────────────────────────
keltner-breakout    Bot         Backtested      2026-02-13
supertrend-v2       Bot         In Development  2026-02-14
vwap-bands          Indicator   Validated       2026-02-12
ema-cross-filter    Indicator   Ported (3/5)    2026-02-10
```

State is derived from artifacts:
- `In Development` — HYPOTHESIS.md exists but no backtest results
- `Backtested` — Backtest results exist
- `Optimized` — Optimization results exist
- `Validated` — Cross-platform validation passed
- `Ported (N/M)` — N of M target platforms implemented
- `Deployed` — Deploy configs generated

### Recent Backtest Results

Scan `.quantdev/strategies/*/backtests/` for the 3 most recent results:
```
Recent Backtests
═══════════════════════════════════════════

Strategy            Date        PF     Sharpe  MaxDD    Trades  Flags
──────────────────────────────────────────────────────────────────────
keltner-breakout    2026-02-13  2.8    1.9     -8.2%    142    —
supertrend-v2       2026-02-11  4.1    3.2     -3.1%     28    ⚠ Sharpe>3, <30 trades
ema-cross           2026-02-10  1.8    1.1     -12.4%   256    —
```

### Pending Validations

Check `.quantdev/strategies/*/indicators/` for implementations without recent validation:
```
Pending Validations
═══════════════════════════════════════════

Indicator           Platforms Built    Last Validated    Status
──────────────────────────────────────────────────────────────
vwap-bands          go,py,pine        2026-02-12        ✓ Current
keltner-channel     go,py,pine,ninja  Never             ⚠ Needs validation
```

### Knowledge Base Stats

If `.quantdev/KNOWLEDGE.md` exists:
```
Knowledge Base
═══════════════════════════════════════════

Entries: {N} findings documented
Last updated: {date}
Topics: {list of section headers}
```

### Current Track

From STATE.json, show what track is active:
```
Current Focus: {Indicator|Bot|Research|None}
Last Action: {description from HISTORY.md}
Updated: {timestamp}
```

</execution>

<output>

## Step 5: Intelligent Routing

Based on the current state, suggest the most appropriate next action:

| State | Suggestion |
|-------|-----------|
| No strategies exist | `/quantdev:indicator` or `/quantdev:bot` — Start building |
| Strategy in development, no backtest | `/quantdev:backtest {name}` — Test the strategy |
| Backtest complete, not optimized | `/quantdev:optimize {name}` — Find better parameters |
| Backtest has warning flags | `/quantdev:risk {name}` — Analyze risk characteristics |
| Indicators not validated | `/quantdev:validate {name}` — Cross-platform check |
| Strategy optimized, no deploy | `/quantdev:deploy {name}` — Generate deployment configs |
| Research in progress | `/quantdev:research {topic}` — Continue research |
| Quick task needed | `/quantdev:quick {description}` — One-off task |

Present the suggestion clearly:
> "**Recommended next step:** `/quantdev:{command}` — {reason}"

If multiple actions are reasonable, list them in priority order.

</output>
