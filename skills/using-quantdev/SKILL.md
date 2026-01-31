---
name: using-quantdev
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<!-- TOKEN BUDGET: 280 lines / ~840 tokens -->

# Using Quantdev

## What is Quantdev?

Quantdev is a Claude Code plugin for systematic trading development. It manages the full lifecycle of trading indicators, bots, and quantitative research across multiple platforms.

**Three tracks:**
- **Indicator Track** — Build, port, and validate indicators across Go, Python, Pine Script, NinjaScript, Tradovate JS
- **Bot Track** — Design, build, test, and prepare trading bots for deployment (never executes live trades)
- **Research Track** — Backtest orchestration, parameter optimization, regime analysis, statistical validation

## Getting Started

1. **`/quantdev:init`** — Configure data paths, platform tiers, execution stack. Creates `.quantdev/`
2. **`/quantdev:indicator keltner`** — Design and build an indicator with TDD
3. **`/quantdev:validate keltner`** — Verify cross-platform consistency
4. **`/quantdev:bot keltner-breakout`** — Build a bot using the indicator
5. **`/quantdev:backtest keltner-breakout`** — Run backtest and analyze results

For quick one-off tasks: `/quantdev:quick 'description'`

## I Want To...

### Indicator Track

| Goal | Command |
|------|---------|
| Design and build a new indicator | `/quantdev:indicator <name>` |
| Validate indicator across platforms | `/quantdev:validate <name>` |
| Port indicator to another platform | `/quantdev:port <name> --to pine` |

### Bot Track

| Goal | Command |
|------|---------|
| Build a new trading bot | `/quantdev:bot <name>` |
| Generate deployment configs | `/quantdev:deploy <name>` |
| Review bot for trading bugs | `/quantdev:review <target>` |

### Research Track

| Goal | Command |
|------|---------|
| Run a backtest | `/quantdev:backtest <strategy>` |
| Optimize parameters | `/quantdev:optimize <strategy>` |
| Conduct market research | `/quantdev:research <topic>` |
| Analyze risk and sizing | `/quantdev:risk <strategy>` |

### Utility

| Goal | Command |
|------|---------|
| Set up project | `/quantdev:init` |
| Check progress | `/quantdev:status` |
| Resume prior session | `/quantdev:resume` |
| Debug a trading bug | `/quantdev:debug` |
| Recover from errors | `/quantdev:recover` |
| Rollback to checkpoint | `/quantdev:rollback` |
| Quick one-off task | `/quantdev:quick "task"` |
| Analyze codebase | `/quantdev:map` |
| Get help | `/quantdev:help` |

## Available Skills

Quantdev provides 12 auto-activating skills. Skills are **behavioral disciplines** — they define HOW to do work.

### Trading-Specific Skills

| Skill | What It Does |
|-------|-------------|
| `quantdev:lookahead-guard` | Scans for future data access, close-price peeking during bar formation, improper indexing. Fires on every indicator/bot code change. |
| `quantdev:regime-awareness` | Injects regime thinking into strategy design and backtest analysis. Segments results by trending/ranging/volatile/low-vol. Flags single-regime dependency. |
| `quantdev:cross-platform-consistency` | Reminds about `/quantdev:validate` after indicator changes. Flags potential drift between platform implementations. |
| `quantdev:risk-discipline` | Validates risk controls: stop losses, daily loss limits, position size bounds, prop firm constraints. Blocks deployment without risk controls. |
| `quantdev:backtest-integrity` | Flags overfitting signals (Sharpe > 3, win rate > 75%), insufficient samples (< 30 trades), missing out-of-sample validation. Auto-annotates results. |

### Process Skills

| Skill | What It Does |
|-------|-------------|
| `quantdev:quantdev-tdd` | Enforces RED-GREEN-REFACTOR. Indicators: golden-file tests. Bots: behavioral tests. Strategies: regression baselines. |
| `quantdev:quantdev-debugging` | 4-phase root cause investigation with trading-first checklist: session boundaries, timezone, bar alignment, data gaps. |
| `quantdev:quantdev-verification` | Blocks completion claims without evidence. Per-track requirements: indicator validation, bot risk checks, research documentation. |
| `quantdev:git-workflow` | Branch lifecycle with trading commit conventions: `feat(keltner): add ATR sensitivity filter`. |
| `quantdev:parallel-dispatch` | Routes 2+ independent tasks to concurrent agents. Pine Script and NinjaScript ports in parallel. |
| `quantdev:documentation` | Strategy journals, knowledge base entries, parameter documentation with rationale, indicator API docs per platform. |
| `quantdev:lessons-learned` | Captures strategy findings to KNOWLEDGE.md, backtest insights, regime observations, parameter sensitivity discoveries. |

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded — follow it directly. Never use the Read tool on skill files.

<activation>

## Skill Activation Protocol

When a trigger condition matches, invoke the corresponding skill before responding.

### File Pattern Triggers
| Pattern | Skill |
|---------|-------|
| `*.pine`, `*.cs`, `*.go`, `*.py`, `*.js` in indicator paths | `quantdev:lookahead-guard`, `quantdev:cross-platform-consistency` |
| `*.test.*`, `*.spec.*`, `__tests__/`, `*_test.go` | `quantdev:quantdev-tdd` |
| Bot code, order logic, position sizing | `quantdev:risk-discipline` |

### Task Marker Triggers
| Marker | Skill |
|--------|-------|
| `tdd="true"` in plan task | `quantdev:quantdev-tdd` |
| Indicator code written or reviewed | `quantdev:lookahead-guard` |
| Backtest results presented | `quantdev:backtest-integrity` |
| Strategy design discussion | `quantdev:regime-awareness` |

### State Condition Triggers
| Condition | Skill |
|-----------|-------|
| About to claim "done", "complete", "fixed" | `quantdev:quantdev-verification` |
| Bug, error, test failure, unexpected behavior | `quantdev:quantdev-debugging` |
| 2+ independent tasks with no shared state | `quantdev:parallel-dispatch` |
| Branch management, commits | `quantdev:git-workflow` |

### Content Pattern Triggers
| Pattern | Skill |
|---------|-------|
| Error, exception, traceback, failure | `quantdev:quantdev-debugging` |
| Indicator, signal, entry/exit logic | `quantdev:lookahead-guard` |
| Backtest, profit factor, sharpe, performance | `quantdev:backtest-integrity` |
| Strategy design, regime, trending/ranging | `quantdev:regime-awareness` |
| Position size, stop loss, risk, daily limit | `quantdev:risk-discipline` |
| Port, convert, cross-platform, validate | `quantdev:cross-platform-consistency` |
| Document, README, API docs, journal | `quantdev:documentation` |
| What did we learn, retrospective, findings | `quantdev:lessons-learned` |

</activation>

<instructions>

## The Core Rule

Invoke relevant skills BEFORE any response or action. If there is a reasonable chance a skill applies, invoke it to check.

Before every response, evaluate triggers in this order:
1. **File patterns** — check files being discussed, modified, or created
2. **Task markers** — check any loaded plans or task definitions
3. **State conditions** — check current workflow state and intent
4. **Content patterns** — check recent output and user messages

If any trigger matches, invoke the skill before responding. Multiple triggers can fire simultaneously.

</instructions>

<rules>

## Conflict Resolution

When multiple skills could activate, follow this priority:

1. **Debugging** (`quantdev-debugging`) — investigate root cause first
2. **Lookahead Guard** (`lookahead-guard`) — catch bias before it propagates
3. **TDD** (`quantdev-tdd`) — tests come before code
4. **Risk Discipline** (`risk-discipline`) — risk before deployment
5. **Verification** (`quantdev-verification`) — evidence before claims
6. **All others** — apply in the order they match

## Red Flags

These thoughts indicate a missed skill invocation:

| Thought | What to do |
|---------|------------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "The indicator looks fine" | Did you check for lookahead? |
| "The backtest results are great" | Did you check integrity? |
| "Let me write the code first" | Did you write the test first? |
| "I'll validate later" | Validate now — drift compounds. |

</rules>

<examples>

## Good: Trading skills fire correctly

User: "Build a Keltner Channel indicator in Go"

Triggers matched:
1. Indicator code → `quantdev:lookahead-guard` (check for bias)
2. New code → `quantdev:quantdev-tdd` (test first)
3. Indicator implementation → `quantdev:cross-platform-consistency` (check siblings)

Result: Write golden-file test first, implement, check for lookahead, remind about validation.

## Good: Multiple trading skills chain

User: "The backtest shows PF of 5.2 and 89% win rate"

Triggers matched:
1. Backtest results → `quantdev:backtest-integrity` (PF > 4, win > 75% = red flags)
2. Strategy performance → `quantdev:regime-awareness` (segment by regime)
3. Suspicious results → `quantdev:lookahead-guard` (likely lookahead bias)

Result: Flag metrics as suspicious, check for lookahead, require regime segmentation.

</examples>
