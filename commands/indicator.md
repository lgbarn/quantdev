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

## Step 3a: Team or Agent Dispatch

**Detection:** Check the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable. When set to `"1"`, teams are available.

**Prompt (conditional):** If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, use `AskUserQuestion` with exactly two options:
- "Team mode (parallel teammates)" — uses TeamCreate/TaskCreate/SendMessage/TeamDelete lifecycle
- "Agent mode (subagents)" — uses standard Task dispatch (current behavior)
- Question text: "Teams available. Use team mode (parallel teammates) or agent mode (subagents)?"

**Silent fallback:** If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unset or not `"1"`, silently set `dispatch_mode` to `agent` with no prompt (zero overhead).

**Variable storage:** Store the result as `dispatch_mode` (value: `team` or `agent`). This variable is referenced by all subsequent dispatch steps.

**Note:** Team mode provides parallelism benefit when building for multiple platforms in Step 5 (parallel builders per platform). Single-agent steps (architect, reviewer) always use Task dispatch regardless of `dispatch_mode`.

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
- Instruction: Implement the indicator for {platform}. Write failing tests first (golden-file pattern), then implement. Follow platform-specific naming conventions (see builder agent for the naming table).

**If dispatch_mode is agent:**
If multiple Tier 1 platforms are selected, dispatch them in parallel using Task tool calls.
Tier 2 and Tier 3 platforms should be dispatched after Tier 1 completes (Tier 1 is source of truth).

**If dispatch_mode is team:**
- `TeamCreate(name: "quantdev-indicator-{indicator-name}")` — create team for parallel platform builds
- `TaskCreate` for each platform build with full context (design, platform idioms, naming conventions)
- `TaskUpdate` to pre-assign owners BEFORE spawning teammates (avoids race conditions)
- `Task(team_name, name, subagent_type: "quantdev:builder")` to spawn each builder teammate
- `TaskList` to monitor progress (poll until all builds complete)
- Tier 2 and Tier 3 platforms dispatch AFTER Tier 1 completes (Tier 1 is source of truth)

## Step 5a: Team Cleanup (team mode only)

**This section applies only when `dispatch_mode` is `team`.**

After all builders complete, run `SendMessage(shutdown_request)` to each teammate, then `TeamDelete`.

**Critical rule:** If `dispatch_mode` is `team` and you are about to exit early (error or user cancellation), you MUST run SendMessage(shutdown_request) + TeamDelete. Never leave orphaned teams running.

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
