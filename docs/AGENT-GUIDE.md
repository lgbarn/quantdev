# Quantdev Agent Guide

Complete reference for all Quantdev agents: their roles, model assignments, dispatch patterns, tool access, restrictions, and relationships.

For model routing configuration, see the [Model Routing Protocol](PROTOCOLS.md#model-routing-protocol).

---

## Agent Overview

| Agent | Default Model | Config Key | Dispatched By | Blocking? | Tool Access |
|-------|--------------|------------|---------------|-----------|-------------|
| **Strategy Architect** | opus | `architecture` | indicator, bot, quick | No | Read, Grep, Glob, Write (designs only) |
| **Builder** | sonnet | `building` | indicator, bot, port, deploy, quick | Yes (blocks review) | Full (Read, Edit, Write, Bash, Grep, Glob) |
| **Reviewer** | sonnet | `review` | indicator, bot, port, review | Yes (blocks progress) | Read, Grep, Glob, Write (reports only) |
| **Strategy Verifier** | sonnet | `validation` | bot, backtest | Yes (gates deployment) | Read, Grep, Glob, Bash (tests), Write |
| **Backtester** | sonnet | `debugging` | backtest | No | Read, Bash (backtest runs), Write |
| **Optimizer** | sonnet | `simplification` | optimize | No | Read, Bash (optimize runs), Write |
| **Risk Analyst** | opus | `security_audit` | risk, optimize | No | Read, Bash (analysis), Write |
| **Cross-Platform Validator** | haiku | `mapping` | validate | Yes (gates cross-platform) | Read, Bash (test execution) |
| **Quant Researcher** | opus | `planning` | research | No | Read, Grep, Glob, WebSearch, WebFetch, Bash, Write |
| **Debugger** | sonnet | `debugging` | debug | No | Read, Grep, Glob, Bash (test commands) |
| **Documenter** | sonnet | `documentation` | (auto after work) | No | Read, Grep, Glob, Write (docs only) |

All model assignments are configurable via `model_routing` in `.quantdev/config.json`. See [Model Selection Guidance](PROTOCOLS.md#model-selection-guidance) for when to upgrade or downgrade.

---

## Pipeline Diagrams

### Indicator Track Pipeline
```
Strategy Architect → Builder → Reviewer → Cross-Platform Validator
     (design)       (implement)  (verify)    (validate platforms)
```

**Commands:** `/quantdev:indicator`, `/quantdev:port`, `/quantdev:validate`

### Bot Track Pipeline
```
Strategy Architect → Builder → Reviewer → Strategy Verifier
     (design)       (implement)  (verify)    (integrity check)
```

**Commands:** `/quantdev:bot`, `/quantdev:deploy`

### Research Track Pipeline
```
Backtester → Strategy Verifier
(orchestrate)   (check overfitting)

Optimizer → Risk Analyst
(sweeps)    (position sizing)
```

**Commands:** `/quantdev:backtest`, `/quantdev:optimize`, `/quantdev:research`, `/quantdev:risk`

---

## Individual Agent Details

### Strategy Architect

- **Model:** opus (configurable via `model_routing.architecture`)
- **Dispatched by:** `/quantdev:indicator`, `/quantdev:bot`, `/quantdev:quick`
- **Max turns:** 20
- **Inputs:** `.quantdev/KNOWLEDGE.md`, `.quantdev/strategies/`, `pkg/indicators/`, `lib/`
- **Outputs:** `.quantdev/strategies/{name}/HYPOTHESIS.md`, indicator design docs, plan files
- **Restrictions:**
  - Cannot edit source code files
  - Cannot create git commits
  - Cannot run build or test commands
  - Must include regime analysis in every strategy design
  - Must specify risk parameters (max loss, per-trade risk, position size)
  - Must define session context for every strategy
- **Why opus:** Novel strategy design and regime-aware reasoning require the strongest model. Designing entry/exit logic, filter composition, and signal flow is complex decomposition work.

### Builder

- **Model:** sonnet (configurable via `model_routing.building`)
- **Dispatched by:** `/quantdev:indicator`, `/quantdev:bot`, `/quantdev:port`, `/quantdev:deploy`, `/quantdev:quick`
- **Max turns:** 30
- **Inputs:** Plan files, CONVENTIONS.md, HYPOTHESIS.md, existing codebase patterns
- **Outputs:** Source code, tests, git commits (one per task), SUMMARY.md
- **Restrictions:**
  - Must follow TDD protocol when `tdd="true"` (test fails before implementation)
  - Must run verify command for every task before marking done
  - Cannot make architectural changes not in the plan
  - Cannot combine tasks into a single commit
  - Cannot skip tests or verification
  - Cannot reference current bar's close in entry/exit logic (lookahead bias)
  - Cannot create bots without risk parameters
  - Stops on checkpoints for human verification/decision
- **Platform expertise:** Pine Script `indicator()` idioms, NinjaScript `OnBarClose()` lifecycle, Go table-driven tests, Python async patterns, platform-specific naming conventions

### Reviewer

- **Model:** sonnet (configurable via `model_routing.review`)
- **Dispatched by:** `/quantdev:indicator`, `/quantdev:bot`, `/quantdev:port`, `/quantdev:review`
- **Max turns:** 20
- **Inputs:** Git diff, plan/spec, SUMMARY.md
- **Outputs:** REVIEW.md
- **Restrictions:**
  - Strict two-stage protocol: Stage 1 (trading correctness) gates Stage 2 (code quality)
  - Cannot edit source code
  - Cannot proceed to Stage 2 if Stage 1 fails
  - Every PASS must include file path evidence
  - Every finding must include file:line and specific remediation
  - Finding categories: Critical (blocks), Important (should fix), Suggestion (nice-to-have)
- **Stage 1 checks:** Lookahead bias, session boundaries, off-by-one bars, fill assumptions, risk parameters
- **Stage 2 checks:** Platform conventions, pattern consistency, error handling, performance

### Strategy Verifier

- **Model:** sonnet (configurable via `model_routing.validation`)
- **Dispatched by:** `/quantdev:bot`, `/quantdev:backtest`
- **Max turns:** 20
- **Inputs:** Strategy code, backtest results, HYPOTHESIS.md
- **Outputs:** VERIFICATION.md
- **Restrictions:**
  - Must complete Stage 1 (code integrity) before Stage 2 (empirical)
  - Cannot mark PASS without concrete evidence
  - Cannot skip overfitting checks
  - Conservative bias: false FAIL > false PASS
- **Stage 1:** Code-level checklist (lookahead bias, fill assumptions, session boundaries, slippage, data integrity)
- **Stage 2:** Empirical verification (IS/OOS comparison, Monte Carlo, parameter sensitivity, overfitting flags, regime segmentation)

### Backtester

- **Model:** sonnet (configurable via `model_routing.debugging`)
- **Adaptive:** Uses haiku for individual run orchestration, sonnet for results analysis
- **Dispatched by:** `/quantdev:backtest`
- **Max turns:** 20
- **Inputs:** HYPOTHESIS.md, PARAMS.json, data files in `data/GLBX/`
- **Outputs:** `.quantdev/strategies/{name}/backtests/{timestamp}-results.md`
- **Restrictions:**
  - Cannot modify source code or strategy parameters
  - Cannot run backtests without checking data availability
  - Cannot report results without overfitting flags
  - Cannot execute live trades
- **Analysis:** Profit factor, Sharpe ratio, max drawdown, win rate, trade count, trade distribution by time/day, overfitting flags

### Optimizer

- **Model:** sonnet (configurable via `model_routing.simplification`)
- **Dispatched by:** `/quantdev:optimize`
- **Max turns:** 25
- **Inputs:** HYPOTHESIS.md, PARAMS.json, Go optimize tools (`cmd/optimize/`, `cmd/optimize-deep/`)
- **Outputs:** `.quantdev/strategies/{name}/optimization/{timestamp}-results.md`
- **Restrictions:**
  - Cannot modify source code or implement parameter changes
  - Cannot run optimization without defining objective
  - Cannot accept sharp-peak optimal parameters without flagging
  - Must run sensitivity analysis alongside optimization
- **Analysis:** Parameter sweeps (grid/walk-forward), sensitivity classification (plateau/slope/peak/noisy), curve-fitting detection, parameter correlation

### Risk Analyst

- **Model:** opus (configurable via `model_routing.security_audit`)
- **Adaptive:** Can downgrade to sonnet for simple sizing checks
- **Dispatched by:** `/quantdev:risk`, `/quantdev:optimize`
- **Max turns:** 20
- **Inputs:** Strategy code, backtest results, Apex account constraints
- **Outputs:** `.quantdev/strategies/{name}/risk-analysis.md`
- **Restrictions:**
  - Cannot modify source code
  - Cannot recommend full Kelly sizing (always fractional)
  - Cannot approve strategies with missing risk parameters
- **Analysis:** Position sizing (fixed fractional, Kelly criterion with 1/4 to 1/2 fraction), drawdown modeling (historical, Monte Carlo), correlation between strategies, portfolio risk, Apex margin validation
- **Why opus:** Position sizing and drawdown modeling require sophisticated reasoning about worst-case scenarios and portfolio interactions.

### Cross-Platform Validator

- **Model:** haiku (configurable via `model_routing.mapping`)
- **Dispatched by:** `/quantdev:validate`
- **Max turns:** 15
- **Inputs:** Golden reference data (`.quantdev/validation/golden/`), platform implementations
- **Outputs:** `.quantdev/validation/{indicator}-validation.md`
- **Restrictions:**
  - Cannot modify source code or golden reference data
  - Cannot mark PASS without running comparisons
  - Must use configurable epsilon tolerance
- **Validation:** Bar-by-bar comparison across Go, Python, Pine Script, NinjaScript, Tradovate JS implementations against golden reference data, flags mathematical drift beyond epsilon
- **Why haiku:** Mechanical comparison task — speed and efficiency matter more than deep reasoning.

### Quant Researcher

- **Model:** opus (configurable via `model_routing.planning`)
- **Dispatched by:** `/quantdev:research`
- **Max turns:** 25
- **Inputs:** `.quantdev/KNOWLEDGE.md`, `.quantdev/strategies/`, `data/GLBX/`, academic sources
- **Outputs:** `.quantdev/research/{topic}/FINDINGS.md`
- **Restrictions:**
  - Cannot edit source code
  - Cannot draw conclusions from insufficient sample sizes (< 30 trades)
  - Cannot confuse statistical significance with practical significance
  - Cannot present overfit metrics without flagging
- **Research domains:** Regime detection, statistical validation, market microstructure, overfitting detection, walk-forward analysis design
- **Why opus:** Statistical analysis, hypothesis testing, and academic literature review require sophisticated reasoning.

### Debugger

- **Model:** sonnet (configurable via `model_routing.debugging`)
- **Adaptive:** Can upgrade to opus for complex multi-platform bugs
- **Dispatched by:** `/quantdev:debug`
- **Max turns:** 20
- **Inputs:** Error description, stack traces, test output, source files
- **Outputs:** ROOT-CAUSE.md
- **Restrictions:**
  - Cannot edit source code (produces remediation plan for builder)
  - Must complete Phase 1 (root cause investigation) before proposing fixes
  - Must base every conclusion on evidence
  - Must check trading-specific issues first (session boundaries, timezones, bar alignment, data gaps)
- **Protocol:** Trading-specific investigation → 5-Whys root cause analysis → Pattern analysis → Remediation plan

### Documenter

- **Model:** sonnet (configurable via `model_routing.documentation`)
- **Dispatched by:** Auto-triggered after indicator/bot/research work
- **Max turns:** 20
- **Inputs:** Git diff, SUMMARY.md files, existing docs, KNOWLEDGE.md
- **Outputs:** Strategy journals (`.quantdev/strategies/{name}/JOURNAL.md`), knowledge base updates, parameter docs, indicator API docs
- **Restrictions:**
  - Cannot edit source code
  - Must update existing docs rather than duplicate
- **Documentation types:** Strategy journals (living document), knowledge base (market observations, patterns, lessons), parameter documentation (optimization history), indicator API docs (formulas, examples, golden-file references)

---

## Agent Communication

Agents **do not communicate directly** with each other. All information exchange happens through artifacts:

| Producer | Artifact | Consumer(s) |
|----------|----------|-------------|
| Strategy Architect | HYPOTHESIS.md, design docs, plans | Builder, Backtester, Strategy Verifier |
| Builder | Source code, tests, git commits, SUMMARY.md | Reviewer, Strategy Verifier, Backtester, Documenter |
| Reviewer | REVIEW.md | Builder (on retry), Orchestrator |
| Strategy Verifier | VERIFICATION.md | Orchestrator |
| Backtester | Backtest results | Strategy Verifier, Optimizer, Risk Analyst, Documenter |
| Optimizer | Optimization results, sensitivity analysis | Risk Analyst, Documenter |
| Risk Analyst | Risk analysis reports | Orchestrator |
| Cross-Platform Validator | Validation reports | Orchestrator |
| Quant Researcher | FINDINGS.md | Strategy Architect, Documenter |
| Debugger | ROOT-CAUSE.md | Builder (for fix implementation) |
| Documenter | Strategy journals, knowledge base, docs | All agents (read as context) |

The **orchestrator** (the main Claude session) manages all agent dispatch and reads all artifacts. Each agent dispatch gets fresh context — no agent has memory of previous dispatches.

---

## Blocking vs Advisory

**Blocking agents** can halt pipeline progress:
- **Builder** — must complete before reviewer runs
- **Reviewer** — Critical findings trigger builder retry (max 2 cycles); persistent failures mark work as `needs_attention`
- **Strategy Verifier** — FAIL verdict prevents deployment
- **Cross-Platform Validator** — FAIL verdict prevents cross-platform release

**Advisory agents** produce reports but don't halt progress:
- **Strategy Architect** — produces designs/plans for user approval
- **Backtester** — produces results with overfitting flags
- **Optimizer** — produces recommendations with curve-fitting warnings
- **Risk Analyst** — produces analysis with risk warnings
- **Quant Researcher** — informs strategy design with findings
- **Debugger** — produces ROOT-CAUSE.md with remediation plan for builder
- **Documenter** — maintains documentation for reference

---

## Common Agent Compositions

Named workflows showing which agents work together for common scenarios.

### Full Indicator Development
```
Strategy Architect → Builder → Reviewer → Cross-Platform Validator → Documenter
```
Standard `/quantdev:indicator` flow. Architect designs math and golden-file tests, Builder implements in Go (source of truth), Reviewer verifies trading correctness, Cross-Platform Validator compares platform implementations, Documenter updates API docs.

### Bot Development with Verification
```
Strategy Architect → Builder → Reviewer → Strategy Verifier → Documenter
```
Standard `/quantdev:bot` flow. Architect designs entry/exit logic and risk parameters, Builder implements, Reviewer checks trading correctness, Strategy Verifier runs integrity checklist and empirical tests, Documenter updates strategy journal.

### Research-Informed Strategy Design
```
Quant Researcher → Strategy Architect → Builder → Reviewer
```
Research-driven development. Researcher investigates market phenomena or statistical properties, findings inform Architect's strategy design, Builder implements, Reviewer verifies.

### Backtest and Optimize Pipeline
```
Backtester → Strategy Verifier → Optimizer → Risk Analyst → Documenter
```
Performance analysis workflow. Backtester runs engine, Strategy Verifier checks for overfitting, Optimizer runs parameter sweeps, Risk Analyst validates position sizing, Documenter captures findings in strategy journal.

### Cross-Platform Port and Validate
```
Builder → Reviewer → Cross-Platform Validator
```
Standard `/quantdev:port` flow. Builder translates indicator to target platform, Reviewer validates platform-specific idioms, Cross-Platform Validator confirms mathematical consistency with golden reference.

### Debug and Fix
```
Debugger → Builder → Reviewer
```
Bug fix workflow. Debugger performs 5-Whys root cause analysis, Builder implements fix from remediation plan, Reviewer verifies correctness.

### Pre-Deploy Quality Gate
```
Reviewer + Strategy Verifier + Risk Analyst (parallel)
```
On-demand quality check. All three agents run in parallel against the bot code. Reviewer checks trading correctness, Strategy Verifier runs integrity checklist, Risk Analyst validates risk parameters and position sizing.
