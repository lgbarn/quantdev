---
description: "Design and build a trading bot with full strategy pipeline"
disable-model-invocation: true
argument-hint: "<strategy-name> [--template keltner|supertrend|ema|vwap|alligator] [--lang go|python]"
---

# /quantdev:bot - Trading Bot Creation Pipeline

You are executing the quantdev bot creation workflow. This is the primary command for the Bot Track — designing, building, reviewing, and verifying a complete trading bot. Follow these steps precisely and in order.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `strategy-name` (REQUIRED): Name for the bot/strategy (e.g., `keltner-breakout`, `vwap-reversion`, `supertrend-trend`).
- `--template` (optional): Use a known bot template. Valid: `keltner`, `supertrend`, `ema`, `vwap`, `alligator`.
- `--lang` (optional): Implementation language. Default: `go`. Valid: `go`, `python`.

If no strategy name is provided, ask the user:
> "What strategy would you like to build? Provide a name or describe the trading concept."

## Step 2: Detect Context

1. Check if `.quantdev/` exists. If not, create a minimal setup.
2. If `.quantdev/config.json` exists, read execution stack, session times, and model routing.
3. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Template Detection

If `--template` was provided OR if the strategy name matches a known template name:

Check if a template skill exists for the strategy:
- `keltner` → skill `bot:keltner`
- `supertrend` → skill `bot:supertrend`
- `ema` → skill `bot:ema`
- `vwap` → skill `bot:vwap`
- `alligator` → skill `bot:alligator`

If a template matches:
> "Template found for {template}. This will use the pre-built strategy design and generate a customized implementation. Proceed with template? (y/n)"

If the user confirms, invoke the template skill via the Skill tool and skip to Step 6 (Reviewer) after it completes.

If no template matches, proceed to Step 4 (custom design).

</prerequisites>

<execution>

## Step 4: Strategy Architect — Design the Strategy

Dispatch a **Strategy Architect agent** (subagent_type: "quantdev:architect") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.architecture` (default: opus)
- max_turns: 20
- The strategy name and any user description
- `.quantdev/KNOWLEDGE.md` if it exists (for accumulated market knowledge)
- Session configuration from config (timezone, RTH, overnight, initial balance)
- Instruction: Design a complete trading strategy. Produce:
  - **Entry rules:** Exact conditions for long and short entries. Indicator composition. Signal logic.
  - **Exit rules:** Stop loss (fixed, trailing, ATR-based), take profit, time-based exits, session close rules.
  - **Filters:** ADX for trend strength, regime detection, time-of-day filters, initial balance filters.
  - **Position sizing:** Fixed fractional, Kelly, or prop firm constraints (Apex limits).
  - **Risk parameters:** Max daily loss, per-trade risk %, position size limits, max concurrent positions.
  - **Regime awareness:** Expected behavior in trending, ranging, and volatile markets. Which regimes to avoid.
  - Write design to `.quantdev/strategies/{strategy-name}/HYPOTHESIS.md`

Present the strategy design to the user for approval before proceeding.

## Step 5: Builder — Implement the Bot

Dispatch a **Builder agent** (subagent_type: "quantdev:builder") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.building` (default: sonnet)
- max_turns: 30
- The strategy design from Step 4
- Implementation language (`go` or `python`)
- Platform-specific context:
  - **Go:** Table-driven tests, backtest engine integration, `strategy.Strategy` interface
  - **Python:** pytest, async patterns for live execution, backtest framework integration
- Session times and timezone from config
- Instruction:
  1. Write behavioral tests first (TDD): "Long entry fires when price > upper Keltner AND ADX > 25"
  2. Implement the strategy following existing bot patterns in the codebase
  3. Include all risk parameters from the design
  4. Handle session boundaries (RTH open/close, overnight transition)
  5. Include proper logging for trade decisions

## Step 6: Reviewer — Check for Trading Bugs

Dispatch a **Reviewer agent** (subagent_type: "quantdev:reviewer") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.review` (default: sonnet)
- max_turns: 20
- The implementation from Step 5
- The strategy design from Step 4
- Instruction: Two-stage review with trading focus.
  - **Stage 1 — Trading correctness:**
    - Lookahead bias: Does the bot use future data? Access close price during an open bar?
    - Fill assumptions: Are limit orders assumed to fill at the limit price? Is slippage modeled?
    - Session boundaries: Does it handle RTH open/close correctly? Overnight positions?
    - Off-by-one: Are bars indexed correctly (`[1]` for last completed bar)?
    - Risk parameters: Are all specified risk limits actually enforced in code?
  - **Stage 2 — Code quality:** Pattern consistency, test coverage, error handling.

If critical issues are found, send back to Builder for fixes and re-review.

## Step 7: Strategy Verifier — Validate Strategy Integrity

Dispatch a **Strategy Verifier agent** (subagent_type: "quantdev:verifier") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.verification` (default: sonnet)
- max_turns: 20
- The reviewed implementation
- Instruction: Two-stage strategy verification.
  - **Stage 1 — Code-level checklist:**
    - [ ] No lookahead bias (future data access)
    - [ ] No close-price-during-bar access
    - [ ] Proper bar indexing
    - [ ] Fill assumptions documented
    - [ ] Slippage modeled or configurable
    - [ ] Commission impact accounted for
    - [ ] All risk parameters present and enforced
    - [ ] Session boundary handling correct
  - **Stage 2 — Empirical (if backtest data available):**
    - Run a quick backtest and check: Sharpe < 3 (not overfit), win rate < 75% (realistic), trade count > 30 (sufficient sample)

## Step 8: Update State & Commit

1. Write initial parameters to `.quantdev/strategies/{strategy-name}/PARAMS.json`
2. Create strategy journal at `.quantdev/strategies/{strategy-name}/JOURNAL.md`
3. Follow **State Update Protocol** (see `docs/PROTOCOLS.md`) — update state
4. Create atomic git commit: `feat({strategy-name}): add {strategy-name} trading bot ({lang})`

</execution>

<output>

## Step 9: Report & Next Steps

Display:
```
Bot: {strategy-name}
Language: {go|python}
Template: {template-name|custom}
Tests: {pass count}/{total}
Verification: {PASS|FAIL with details}
Files created: {count}
{list of files}
```

Suggest next steps:
> "Bot built successfully. Next steps:"
> - `/quantdev:backtest {strategy-name}` — Run backtest against historical data
> - `/quantdev:optimize {strategy-name}` — Parameter sweep for optimal settings
> - `/quantdev:risk {strategy-name}` — Position sizing and drawdown analysis
> - `/quantdev:deploy {strategy-name}` — Generate deployment configs (Docker, systemd)

</output>
