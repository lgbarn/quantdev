---
description: "Analyze trading codebase — indicator inventory, strategy catalog, cross-platform coverage"
disable-model-invocation: true
argument-hint: "[focus] — all (default), indicators, strategies, backtests, coverage"
---

# /quantdev:map - Trading Codebase Analysis

You are executing trading codebase analysis. This maps your indicator inventory, strategy catalog, backtest history, and cross-platform coverage gaps. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `focus` (optional): Analysis focus area. Accepts:
  - **No argument / "all"**: Run all focus areas in parallel
  - **"indicators"**: Map indicator inventory — by platform, by type (trend, momentum, volatility, volume), implementation status, test coverage (produces INDICATORS.md)
  - **"strategies"**: Map strategy catalog — active bots, templates used, parameters, last backtest (produces STRATEGIES.md)
  - **"backtests"**: Map backtest history — results by strategy, performance trends, data coverage periods (produces BACKTESTS.md)
  - **"coverage"**: Map cross-platform coverage — which indicators exist on which platforms, gaps, validation status (produces COVERAGE.md)

## Step 2: Detect Context

1. Check if `.quantdev/` exists (optional — this command works anywhere with trading code).
2. If `.quantdev/config.json` exists, read `platforms` for tier configuration and `model_routing` for agent selection.
3. Otherwise, use default model: **sonnet**.
4. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 2a: Team or Agent Dispatch

**Detection:** Check the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable. When set to `"1"`, teams are available.

**Prompt (conditional):** If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, use `AskUserQuestion` with exactly two options:
- "Team mode (parallel teammates)" — uses TeamCreate/TaskCreate/SendMessage/TeamDelete lifecycle
- "Agent mode (subagents)" — uses standard Task dispatch (current behavior)

Question text: "Teams available. Use team mode (parallel teammates) or agent mode (subagents)?"

**Silent fallback:** If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unset or not `"1"`, silently set `dispatch_mode` to `agent` with no prompt (zero overhead).

**Variable storage:** Store the result as `dispatch_mode` (value: `team` or `agent`). This variable is referenced by all subsequent dispatch steps.

**Note:** Team mode provides parallelism benefit only for `map all` (4 builder agents in parallel). Single-focus maps always use Task dispatch regardless of `dispatch_mode`.

</prerequisites>

<execution>

## Step 3: Build Agent Context

Assemble context per **Agent Context Protocol** (see `docs/PROTOCOLS.md`):
- The focus area from Step 1
- Working directory, current branch, and worktree status
- `.quantdev/PROJECT.md` (if exists)
- Platform tier configuration from config

## Step 4: Dispatch Analysis

**Single focus:**

**Dispatch:** Always uses Task dispatch (single-agent step — team overhead not justified). This applies regardless of `dispatch_mode`.

Dispatch a **Builder agent in read-only mode** (subagent_type: "quantdev:builder") with:
- Follow **Model Routing Protocol** — resolve model (default: sonnet)
- max_turns: 20
- All context from Step 3
- Instruction based on focus:

  **Indicators:** Scan for all indicator implementations across platforms. For each indicator, record:
  - Name, type (trend/momentum/volatility/volume/composite)
  - Platforms implemented (Go, Python, Pine Script, NinjaScript, Tradovate)
  - Test coverage (has tests? golden-file tests?)
  - Last validation date (from `.quantdev/validation/`)
  - Parameters and defaults

  **Strategies:** Scan for all strategy/bot implementations. For each strategy, record:
  - Name, template used (if any), implementation language
  - Indicators used, entry/exit logic summary
  - Current parameters (from PARAMS.json)
  - Last backtest date and key metrics
  - State (development, backtested, optimized, deployed)

  **Backtests:** Scan `.quantdev/strategies/*/backtests/` for all results. For each, record:
  - Strategy name, date, data period
  - Key metrics (PF, Sharpe, MaxDD, trades)
  - Warning flags
  - Performance trend over time (improving/degrading/stable)

  **Coverage:** Build a matrix of indicators × platforms. For each cell:
  - Implemented? (yes/no)
  - Tested? (yes/no)
  - Validated against golden data? (yes/no/never)
  - Last validation date

**All focuses (parallel):**

**If dispatch_mode is agent:**
Dispatch **4 builder agents** in parallel, one per focus area (indicators, strategies, backtests, coverage), each with the same context but different focus instructions.

**If dispatch_mode is team:**
1. `TeamCreate(name: "quantdev-map-all")` — create a single team
2. For each of the 4 focus areas, `TaskCreate` with appropriate subject and description
3. `TaskUpdate` to pre-assign each task to a specific teammate name
4. For each task, `Task(team_name: "quantdev-map-all", name: "builder-{focus}", subagent_type: "quantdev:builder")` to spawn the teammate
5. Monitor progress via `TaskList` — poll until all 4 tasks reach a terminal state
6. `SendMessage(shutdown_request)` to all teammates, then `TeamDelete(name: "quantdev-map-all")`

## Team Cleanup

**This section applies only when `dispatch_mode` is `team` and focus is `all`.**

After all tasks complete, verify that the team has been properly cleaned up:
1. Confirm `SendMessage(shutdown_request)` was sent to all teammates
2. Confirm `TeamDelete(name: "quantdev-map-all")` was called
3. If the team was not cleaned up (due to an error or early exit), run the shutdown + delete now

**Critical rule:** If `dispatch_mode` is `team` and you are about to exit early, you MUST run SendMessage(shutdown_request) + TeamDelete. Never leave orphaned teams running.

</execution>

<output>

## Step 5: Save Results

1. Delete any existing codebase docs: remove all files in `.quantdev/codebase/` (create the directory if it doesn't exist)
2. Write the new analysis document(s) to `.quantdev/codebase/`
3. Display a summary:

```
Trading Codebase Map
═══════════════════════════════════════════

Indicators: {N} total across {M} platforms
  Go: {N}  Python: {N}  Pine: {N}  Ninja: {N}  Tradovate: {N}

Strategies: {N} total
  Active: {N}  In Development: {N}  Deployed: {N}

Backtests: {N} results on file
  Best PF: {strategy} ({PF})  Worst MaxDD: {strategy} ({DD%})

Coverage Gaps:
  {indicator}: missing {platform} implementation
  {indicator}: never validated across platforms
```

Offer follow-up:
> "Would you like me to:
> - Analyze a specific focus area in more detail
> - `/quantdev:validate {indicator}` — Validate an indicator with coverage gaps
> - `/quantdev:port {file} {platform}` — Port an indicator to fill a gap"

</output>
