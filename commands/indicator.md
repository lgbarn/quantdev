---
description: "Design and build a new technical indicator across platforms"
disable-model-invocation: true
argument-hint: "<indicator-name> [--platforms go,python,pinescript]"
---

# /quantdev:indicator - Indicator Design & Build

You are executing the quantdev indicator creation workflow. This is the primary command for the Indicator Track. Follow these steps precisely and in order.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `indicator-name` (REQUIRED): The indicator to build (e.g., `keltner-channel`, `supertrend`, `ema-cross`, `vwap-bands`).
- `--platforms` (optional): Comma-separated target platforms. Default: all Tier 1 platforms from config.

If no indicator name is provided, ask the user:
> "What indicator would you like to build? Provide a name or describe the concept."

## Step 2: Detect Context

1. Check if `.quantdev/` exists. If not, create a minimal setup (indicator work doesn't require full init).
2. If `.quantdev/config.json` exists, read `platforms` for tier configuration and `model_routing` for agent selection.
3. Otherwise, use defaults: Tier 1 = go, python; Tier 2 = pinescript; Tier 3 = ninjatrader, tradovate.
4. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Platform Selection

If `--platforms` was not specified, ask the user:

Use `AskUserQuestion` with 1 question:

1. **Target platforms** — "Which platforms should this indicator target?"
   - `Tier 1 only (Go + Python) (Recommended)` — Source of truth implementations. Best for backtesting and live use.
   - `Tier 1 + Pine Script` — Adds charting platform. Most common choice.
   - `All platforms` — Go, Python, Pine Script, NinjaScript, Tradovate JS. Full coverage.
   - (User can also specify custom selection via "Other")

</prerequisites>

<execution>

## Step 4: Strategy Architect — Design the Math

Dispatch a **Strategy Architect agent** (subagent_type: "quantdev:architect") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.architecture` (default: opus)
- max_turns: 20
- The indicator name and any user description
- `.quantdev/PROJECT.md` and `.quantdev/KNOWLEDGE.md` if they exist
- Instruction: Design the indicator mathematics. Produce:
  - Mathematical formula (LaTeX notation)
  - Input parameters with defaults and valid ranges
  - Expected behavior in trending vs ranging vs volatile regimes
  - Edge cases: first N bars (warmup period), session boundaries, data gaps
  - Output values and their interpretation
  - Write design to `.quantdev/strategies/{indicator-name}/HYPOTHESIS.md`

Wait for the architect to complete. Present the design to the user for approval before proceeding.

## Step 5: Builder — Implement Per Platform

For each target platform, dispatch a **Builder agent** (subagent_type: "quantdev:builder") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.building` (default: sonnet)
- max_turns: 30
- The indicator design from Step 4
- Platform-specific context:
  - **Go:** Table-driven tests in `_test.go`, golden-file validation
  - **Python:** pytest fixtures, numpy/pandas idioms
  - **Pine Script:** `indicator()` declaration, `plot()` calls, `barstate` awareness
  - **NinjaScript C#:** `OnBarClose()` lifecycle, `AddPlot()`, ISeries pattern
  - **Tradovate JS:** Module exports, `map()` pattern, `init()`/`next()` lifecycle
- Instruction: Implement the indicator for {platform}. Write failing tests first (golden-file pattern), then implement. Follow LB naming conventions.

If multiple Tier 1 platforms are selected, dispatch them in parallel.
Tier 2 and Tier 3 platforms should be dispatched after Tier 1 completes (Tier 1 is source of truth).

## Step 6: Reviewer — Check for Trading Bugs

Dispatch a **Reviewer agent** (subagent_type: "quantdev:reviewer") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.review` (default: sonnet)
- max_turns: 20
- All implementations from Step 5
- The indicator design from Step 4
- Instruction: Two-stage review.
  - **Stage 1 — Trading correctness:** Lookahead bias, session boundary handling, warmup period correctness, off-by-one bar errors, proper indexing (`[1]` not `[0]` for completed bars), NaN/null handling during warmup.
  - **Stage 2 — Code quality:** Pattern consistency across platforms, naming conventions, test coverage.

If critical issues are found, loop back: send findings to the Builder for fixes, then re-review.

## Step 7: Update State & Commit

1. Write parameter defaults to `.quantdev/strategies/{indicator-name}/PARAMS.json`
2. Follow **State Update Protocol** (see `docs/PROTOCOLS.md`) — update state with indicator completion
3. Create atomic git commit: `feat({indicator-name}): add {indicator-name} indicator for {platforms}`

</execution>

<output>

## Step 8: Report & Next Steps

Display:
```
Indicator: {indicator-name}
Platforms: {list of platforms built}
Tests: {pass count}/{total count}
Files created: {count}
{list of files}
```

Suggest next steps:
> "Indicator built successfully. Next steps:"
> - `/quantdev:validate {indicator-name}` — Run cross-platform golden-file comparison
> - `/quantdev:port {file} {platform}` — Port to additional platforms
> - `/quantdev:backtest {strategy}` — If this indicator is part of a strategy, run a backtest

</output>
