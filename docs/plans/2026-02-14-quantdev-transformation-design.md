# Quantdev — Trading Development Plugin Design

> Transforming Shipyard (dev workflow framework) into quantdev, a Claude Code plugin
> purpose-built for systematic trading development.

**Date:** 2026-02-14
**Author:** lgbarn
**Repo:** github.com/lgbarn/quantdev (new repo, fresh history)
**License:** MIT

---

## 1. Identity & Purpose

**quantdev** is a personal Claude Code plugin for systematic trading development. It
manages the full lifecycle of trading indicators, bots, and quantitative research.

**What it is NOT:** A generic dev workflow tool. Every agent, skill, and command is
designed around trading concepts — strategies, regimes, backtests, risk — not software
phases and sprints.

**Target user:** lgbarn (personal tool). Hardcoded for:

- **Data:** Local CSV/Parquet files (Databento manual downloads) in `data/GLBX/`
- **Live data:** TopStepX connection
- **Execution:** Apex API direct
- **Markets:** US futures, ET session times
- **Branding:** LB conventions

---

## 2. Three Tracks

### 2.1 Indicator Track

Build, port, and validate technical indicators across platforms.

- Design indicator math with Strategy Architect
- Implement per platform with Builder
- Verify cross-platform consistency with Cross-Platform Validator
- Absorbs existing `analyze`, `convert`, `cleanup` skills

### 2.2 Bot Track

Design, build, test, and prepare trading bots for deployment.

- Strategy Architect designs entry/exit logic, filter composition, signal flow
- Builder implements in Go or Python following existing patterns
- Strategy Verifier checks for lookahead bias, fill assumptions, slippage
- Absorbs existing bot templates (keltner, supertrend, ema, vwap, alligator)
- Generates deployment configs (Docker, systemd) — never executes live trades

### 2.3 Research Track

Backtest orchestration, parameter optimization, statistical validation.

- Backtester orchestrates Go backtest engine against local data
- Optimizer runs parameter sweeps with overfitting detection
- Quant Researcher conducts regime analysis, statistical tests
- Risk Analyst models drawdowns, position sizing, portfolio risk
- All findings feed into the knowledge base

---

## 3. Platform Tiers

| Tier | Platforms | Role |
|------|-----------|------|
| **Tier 1** | Go, Python | Source of truth for math. Backtesting engine. Live bots. |
| **Tier 2** | Pine Script | Primary charting platform. Most prolific indicator library. |
| **Tier 3** | NinjaScript C#, Tradovate JS | Port when needed. Secondary priority. |

---

## 4. Agents (11 Total)

### 4.1 Kept from Shipyard (4)

#### Builder
- **Model:** Sonnet
- **Role:** Writes indicator/bot code with TDD. Understands Pine Script idioms,
  NinjaScript `OnBarClose()` lifecycle, Go table-driven tests, Python async patterns.
  Follows LB naming conventions.
- **Tools:** Read, Edit, Write, Bash, Grep, Glob
- **Max turns:** 30

#### Reviewer
- **Model:** Sonnet
- **Role:** Two-stage code review. Stage 1: trading correctness (lookahead bias,
  session boundary bugs, off-by-one bar errors, fill assumptions). Stage 2: code
  quality and pattern consistency.
- **Tools:** Read-only
- **Max turns:** 20

#### Debugger
- **Model:** Sonnet/Opus (adaptive)
- **Role:** 5-Whys root cause analysis for trading bugs. Checks session boundaries,
  timezone issues, bar alignment, data gaps, indicator divergence across platforms,
  backtest vs live discrepancies.
- **Tools:** Read, Bash (test only)
- **Max turns:** 20

#### Documenter
- **Model:** Sonnet
- **Role:** Maintains strategy journals, knowledge base entries, parameter
  documentation, indicator API docs.
- **Tools:** Read, Write (docs only)
- **Max turns:** 20

### 4.2 Transformed (3)

#### Strategy Architect (was: Architect)
- **Model:** Opus
- **Role:** Designs strategy logic — entry/exit rules, indicator composition, filter
  layering, signal flow. Regime-aware. Proposes ADX filters for trending strategies,
  mean-reversion guards for ranging markets. Reasons about market microstructure.
- **Tools:** Read, Write (plans/designs only)
- **Max turns:** 20

#### Quant Researcher (was: Researcher)
- **Model:** Opus
- **Role:** Statistical analysis, regime detection, market microstructure research.
  Reviews academic literature. Reasons about statistical significance, overfitting,
  sample size, survivorship bias. Conducts walk-forward analysis design.
- **Tools:** Read, WebSearch, WebFetch, Bash (data analysis)
- **Max turns:** 25

#### Strategy Verifier (was: Verifier)
- **Model:** Sonnet
- **Role:** Two-stage strategy verification. Stage 1: code-level checklist (lookahead
  bias, future peeking, close-price-during-bar access, improper indexing, fill
  assumptions, slippage modeling, commission impact). Stage 2: empirical statistical
  verification (in-sample vs out-of-sample comparison, Monte Carlo simulation,
  parameter sensitivity testing, equity curve analysis).
- **Tools:** Read, Bash (backtest/test execution)
- **Max turns:** 20

### 4.3 New (4)

#### Backtester
- **Model:** Sonnet/Haiku (adaptive — Haiku for individual runs, Sonnet for analysis)
- **Role:** Orchestrates Go backtest engine runs against local CSV/Parquet data.
  Analyzes results: profit factor, Sharpe ratio, max drawdown, win rate, average
  win/loss ratio, trade count, trade distribution by time/day. Compares strategies
  side by side. Flags suspicious metrics.
- **Tools:** Read, Bash (backtest execution), Write (results)
- **Max turns:** 20

#### Optimizer
- **Model:** Sonnet
- **Role:** Parameter sweeps using Go optimize tooling. Sensitivity analysis ("how
  fragile is this strategy to ATR multiplier changes?"). Walk-forward optimization
  windows. Detects curve-fitting: identifies robust parameter plateaus vs brittle
  peaks. Correlation analysis between parameters. Generates heatmaps and
  sensitivity reports.
- **Tools:** Read, Bash (optimization runs), Write (results)
- **Max turns:** 25

#### Risk Analyst
- **Model:** Opus
- **Role:** Position sizing analysis (fixed fractional, Kelly criterion, prop firm
  constraints). Drawdown modeling (max drawdown, recovery time, underwater periods).
  Correlation analysis between strategies. Portfolio-level risk assessment. Validates
  risk parameters: daily max loss limits, per-trade risk, position size limits,
  margin requirements for Apex accounts.
- **Tools:** Read, Bash (analysis), Write (reports)
- **Max turns:** 20

#### Cross-Platform Validator
- **Model:** Haiku
- **Role:** Compares indicator outputs across Go, Python, Pine Script, NinjaScript,
  and Tradovate JS implementations against golden reference data in
  `.quantdev/validation/golden/`. Runs each implementation with identical inputs,
  collects outputs, computes differences. Flags mathematical drift beyond tolerance
  (configurable epsilon). Reports which platform diverged and on which bar.
- **Tools:** Read, Bash (test execution)
- **Max turns:** 15

---

## 5. Commands (18 Total)

### 5.1 Core Lifecycle (5)

| Command | Purpose |
|---------|---------|
| `/quantdev:init` | Configure project: data paths, platform tiers, execution stack. Creates `.quantdev/` |
| `/quantdev:status` | Dashboard: active strategies, recent backtests, pending validations, knowledge base stats |
| `/quantdev:resume` | Restore prior session context |
| `/quantdev:recover` | Error recovery for interrupted work |
| `/quantdev:rollback` | Git checkpoint rollback |

### 5.2 Indicator Track (3)

| Command | Agents | Purpose |
|---------|--------|---------|
| `/quantdev:indicator` | Strategy Architect → Builder → Reviewer | Design and build a new indicator |
| `/quantdev:validate` | Cross-Platform Validator | Golden-file comparison across platform implementations |
| `/quantdev:port` | Builder → Reviewer | Translate indicator to another platform |

### 5.3 Bot Track (2)

| Command | Agents | Purpose |
|---------|--------|---------|
| `/quantdev:bot` | Strategy Architect → Builder → Reviewer → Strategy Verifier | Full bot creation pipeline with strategy templates |
| `/quantdev:deploy` | Builder | Generate Docker/systemd deployment configs (never executes live) |

### 5.4 Research Track (3)

| Command | Agents | Purpose |
|---------|--------|---------|
| `/quantdev:backtest` | Backtester → Strategy Verifier | Orchestrate Go engine, analyze results, verify integrity |
| `/quantdev:optimize` | Optimizer → Risk Analyst | Parameter sweeps, sensitivity analysis, overfitting detection |
| `/quantdev:research` | Quant Researcher | Regime analysis, statistical tests, academic review |

### 5.5 Quality Gates (2)

| Command | Agents | Purpose |
|---------|--------|---------|
| `/quantdev:review` | Reviewer | On-demand code review with trading-specific concerns |
| `/quantdev:risk` | Risk Analyst | Position sizing, drawdown modeling, portfolio risk |

### 5.6 Utility (3)

| Command | Agents | Purpose |
|---------|--------|---------|
| `/quantdev:map` | Builder (read-only) | Analyze trading codebase structure and inventory |
| `/quantdev:debug` | Debugger | Root cause analysis for trading bugs |
| `/quantdev:quick` | Adaptive | One-off tasks |
| `/quantdev:help` | — | Command reference |

---

## 6. Skills (12 Auto-Activating)

### 6.1 Adapted from Shipyard (7)

| Skill | Triggers | Behavior |
|-------|----------|----------|
| **quantdev-tdd** | Writing new indicator/bot code | Test-first. Indicators: golden-file tests. Bots: behavioral tests. Strategies: regression baselines (profit factor, drawdown). Agent decides which layer. |
| **quantdev-debugging** | Errors, test failures, signal mismatch | 5-Whys with trading context. Checks session boundaries, timezone issues, bar alignment, data gaps first. |
| **quantdev-verification** | Before marking work complete | Evidence-based. Backtest ran? Validation passed? Regression baselines intact? |
| **git-workflow** | Branch management, commits | Atomic commits. Convention: `feat(keltner): add ATR period sensitivity filter` |
| **parallel-dispatch** | 2+ independent tasks | Route concurrent work — e.g., Pine Script and NinjaScript ports in parallel. |
| **documentation** | After indicator/bot/research work | Auto-maintains strategy journals, knowledge base, parameter docs. |
| **lessons-learned** | After validation, post-backtest | Captures findings to KNOWLEDGE.md. |

### 6.2 New Trading-Specific (5)

| Skill | Triggers | Behavior |
|-------|----------|----------|
| **lookahead-guard** | Indicator or signal code written/reviewed | Scans for future data access, close-price peeking during bar, improper indexing `[0]` vs `[1]`. Fires on Builder and Reviewer. |
| **regime-awareness** | Strategy design, backtest analysis, optimization | Injects regime thinking. Segments results by trending/ranging/volatile. Warns about single-regime strategies. |
| **cross-platform-consistency** | Indicator code changes on any platform | Reminds to run `/quantdev:validate`. Flags potential drift. |
| **risk-discipline** | Bot code, position sizing, order logic | Validates risk parameters exist: max daily loss, per-trade risk, position limits. Flags missing stops, unbounded sizes. |
| **backtest-integrity** | Backtest results analysis | Flags overfitting signals: Sharpe > 3, win rate > 75%, smooth equity curve, < 30 trades, no OOS testing. |

---

## 7. Hooks (5)

| Hook | Trigger | Behavior |
|------|---------|----------|
| **SessionStart** | startup, resume, clear, compact | Loads `.quantdev/STATE.json`, active strategy context, recent backtest results, knowledge base. Adaptive: light for quick tasks, full for research. |
| **TeammateIdle** | Teammate finishes (team mode) | Verifies tests pass, validation clean, no regression in baselines. |
| **TaskCompleted** | Task completes | Track-specific evidence. Indicator: validation ran? Bot: tests pass, no lookahead bias? Research: findings documented? |
| **PostBacktest** | Backtest run completes | Auto-flags: Sharpe > 3 (overfit), win rate > 75% (suspicious), < 30 trades (insufficient), no OOS test, equity curve too smooth. Writes to strategy journal. |
| **Stop** | Session ends | Persists state, notes in-progress work. |

---

## 8. Project State Structure

```
.quantdev/
├── config.json                 # platforms, data paths, execution stack, model routing
├── PROJECT.md                  # trading system vision, goals, asset focus
├── KNOWLEDGE.md                # accumulated market/strategy knowledge base
├── STATE.json                  # machine state (active track, current strategy)
├── STATE.json.bak              # automatic backup
├── strategies/
│   └── {strategy-name}/
│       ├── HYPOTHESIS.md       # strategy thesis, assumptions, expected regime
│       ├── PARAMS.json         # current parameter set with history
│       ├── indicators/         # indicator source per platform
│       ├── backtests/          # timestamped backtest results
│       ├── optimization/       # parameter sweep results
│       └── JOURNAL.md          # living document: changes, observations, lessons
├── research/
│   └── {topic}/
│       ├── FINDINGS.md         # research conclusions
│       └── data/               # supporting data
├── validation/
│   └── golden/                 # cross-platform reference data
└── quick/                      # one-off task artifacts
```

### Config Schema

```json
{
  "platforms": {
    "tier1": ["go", "python"],
    "tier2": ["pinescript"],
    "tier3": ["ninjatrader", "tradovate"]
  },
  "data": {
    "historical_path": "data/GLBX",
    "formats": ["csv", "parquet"],
    "source": "databento_manual_download"
  },
  "execution": {
    "provider": "apex",
    "api": "direct",
    "paper_mode": true
  },
  "live_data": {
    "provider": "topstepx"
  },
  "sessions": {
    "timezone": "America/New_York",
    "rth": ["09:30", "16:00"],
    "initial_balance": ["09:30", "10:30"],
    "overnight": ["18:00", "09:30"]
  },
  "model_routing": "adaptive",
  "knowledge_base": true
}
```

---

## 9. Model Routing (Adaptive)

The plugin auto-routes based on task complexity:

| Complexity | Model | Examples |
|------------|-------|---------|
| **Deep reasoning** | Opus | Novel strategy design, statistical analysis, risk modeling, complex debugging |
| **Standard work** | Sonnet | Building code, reviewing, porting, optimization analysis |
| **Fast validation** | Haiku | Cross-platform comparison, individual backtest runs, simple verification |

Agent defaults:

| Agent | Default | Adaptive Override |
|-------|---------|-------------------|
| Strategy Architect | Opus | — |
| Quant Researcher | Opus | — |
| Risk Analyst | Opus | Sonnet for simple sizing checks |
| Builder | Sonnet | — |
| Reviewer | Sonnet | — |
| Strategy Verifier | Sonnet | Haiku for checklist-only (stage 1) |
| Optimizer | Sonnet | — |
| Backtester | Sonnet | Haiku for individual run orchestration |
| Debugger | Sonnet | Opus for complex multi-system bugs |
| Documenter | Sonnet | — |
| Cross-Platform Validator | Haiku | — |

---

## 10. Testing Philosophy

Agent decides which testing layer based on context:

| Layer | When | Example |
|-------|------|---------|
| **Unit (math correctness)** | Indicator functions | Golden-file: EMA(closes, 20) → expected values |
| **Behavioral** | Signal logic | "Long entry fires when price > upper Keltner AND ADX > 25" |
| **Regression** | Strategy changes | Backtest key metrics (PF, Sharpe, drawdown) compared against baseline |

Follows existing patterns:
- Go: table-driven tests, `_test.go` files
- NinjaScript: helper test classes
- Python: pytest with fixtures

---

## 11. Transformation Summary

### Removed from Shipyard
- **Agents:** auditor, simplifier, mapper
- **Commands:** ship, audit, simplify, brainstorm, plan, build, document, worktree,
  settings, move-docs (11 commands)
- **Skills:** security-audit, infrastructure-validation, code-simplification,
  shipyard-brainstorming, shipyard-writing-plans, shipyard-executing-plans,
  shipyard-testing, shipyard-writing-skills (8 skills)
- **Theming:** All nautical metaphors (phases, waves, shipping)

### Added
- **Agents:** Backtester, Optimizer, Risk Analyst, Cross-Platform Validator (4 new)
- **Agent transformations:** Architect → Strategy Architect, Researcher → Quant
  Researcher, Verifier → Strategy Verifier (3 transformed)
- **Commands:** indicator, validate, port, bot, deploy, backtest, optimize, research,
  risk (9 new, 9 adapted)
- **Skills:** lookahead-guard, regime-awareness, cross-platform-consistency,
  risk-discipline, backtest-integrity (5 new)
- **Hooks:** PostBacktest (1 new)
- **Structure:** Strategy-centric `.quantdev/` with knowledge base
- **Bot templates:** Absorbed from existing skills

### Kept (Adapted)
- **Agents:** Builder, Reviewer, Debugger, Documenter (4)
- **Skills:** tdd, debugging, verification, git-workflow, parallel-dispatch,
  documentation, lessons-learned (7)
- **Hooks:** SessionStart, TeammateIdle, TaskCompleted, Stop (4)
- **Infrastructure:** State scripts, checkpoint system, team detection, bats tests

---

## 12. Implementation Order

### Phase 1: Foundation
1. Initialize git repo, set up package.json as `@lgbarn/quantdev`
2. Rename all `shipyard` references to `quantdev`
3. Update `.claude-plugin/plugin.json` and `marketplace.json`
4. Remove Shipyard-specific agents, commands, skills that are being dropped
5. Update hooks and scripts for quantdev naming

### Phase 2: Agent Definitions
6. Transform architect → Strategy Architect agent spec
7. Transform researcher → Quant Researcher agent spec
8. Transform verifier → Strategy Verifier agent spec
9. Create Backtester agent spec
10. Create Optimizer agent spec
11. Create Risk Analyst agent spec
12. Create Cross-Platform Validator agent spec
13. Update Builder, Reviewer, Debugger, Documenter with trading context

### Phase 3: Commands
14. Build core lifecycle commands (init, status, resume, recover, rollback)
15. Build indicator track commands (indicator, validate, port)
16. Build bot track commands (bot, deploy)
17. Build research track commands (backtest, optimize, research)
18. Build quality gate commands (review, risk)
19. Build utility commands (map, debug, quick, help)

### Phase 4: Skills
20. Adapt 7 existing skills with trading context
21. Create lookahead-guard skill
22. Create regime-awareness skill
23. Create cross-platform-consistency skill
24. Create risk-discipline skill
25. Create backtest-integrity skill

### Phase 5: Hooks & Infrastructure
26. Update SessionStart for trading context loading
27. Update TeammateIdle and TaskCompleted for trading evidence
28. Create PostBacktest hook
29. Update state scripts for `.quantdev/` structure
30. Absorb bot templates into bot command

### Phase 6: Documentation & Testing
31. Write README.md for quantdev
32. Update docs (AGENT-GUIDE, PROTOCOLS, QUICKSTART)
33. Adapt bats test suite
34. Push to github.com/lgbarn/quantdev
