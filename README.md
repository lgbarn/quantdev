# Quantdev

A Claude Code plugin for systematic trading development. Build indicators, bots, and quantitative research across Go, Python, Pine Script, NinjaScript, and Tradovate platforms.

Personal tool for lgbarn.

## Description

Quantdev organizes trading development into three tracks:

- **Indicator Track**: Design, implement, and validate technical indicators across platforms with golden-file consistency testing
- **Bot Track**: Build trading bots with strategy templates, lookahead bias detection, and deployment configuration
- **Research Track**: Backtest orchestration, parameter optimization, regime analysis, and risk modeling

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated
- `jq` (used by session hooks for state injection)
- Go 1.21+ (for backtesting engine)
- Python 3.11+ (for trading bots)

## Installation

### From GitHub

```bash
claude plugin marketplace add lgbarn/quantdev
claude plugin install quantdev@quantdev
```

### From a local clone

```bash
git clone git@github.com:lgbarn/quantdev.git
claude plugin marketplace add /absolute/path/to/quantdev
claude plugin install quantdev@quantdev
```

### Verify

```bash
claude /quantdev:status
```

## Quick Start

### Indicator Track

```bash
# Configure project
/quantdev:init

# Design and build a new indicator
/quantdev:indicator

# Validate cross-platform consistency
/quantdev:validate
```

### Bot Track

```bash
# Build a trading bot
/quantdev:bot

# Review for lookahead bias and correctness
/quantdev:review

# Generate deployment configs
/quantdev:deploy
```

### Research Track

```bash
# Run backtest
/quantdev:backtest

# Parameter optimization
/quantdev:optimize

# Risk analysis
/quantdev:risk
```

## Commands

### Lifecycle

| Command | Purpose |
|---------|---------|
| `/quantdev:init` | Configure project: data paths, platform tiers, execution stack |
| `/quantdev:status` | Dashboard: active strategies, recent backtests, pending validations |
| `/quantdev:resume` | Restore prior session context |
| `/quantdev:recover` | Error recovery for interrupted work |
| `/quantdev:rollback` | Git checkpoint rollback |

### Indicator Track

| Command | Purpose |
|---------|---------|
| `/quantdev:indicator` | Design and build a new indicator |
| `/quantdev:validate` | Golden-file comparison across platform implementations |
| `/quantdev:port` | Translate indicator to another platform |

### Bot Track

| Command | Purpose |
|---------|---------|
| `/quantdev:bot` | Full bot creation pipeline with strategy templates |
| `/quantdev:deploy` | Generate Docker/systemd deployment configs (never executes live) |

### Research Track

| Command | Purpose |
|---------|---------|
| `/quantdev:backtest` | Orchestrate Go engine, analyze results, verify integrity |
| `/quantdev:optimize` | Parameter sweeps, sensitivity analysis, overfitting detection |
| `/quantdev:research` | Regime analysis, statistical tests, academic review |

### Quality Gates

| Command | Purpose |
|---------|---------|
| `/quantdev:review` | On-demand code review with trading-specific concerns |
| `/quantdev:risk` | Position sizing, drawdown modeling, portfolio risk |

### Utility

| Command | Purpose |
|---------|---------|
| `/quantdev:map` | Analyze trading codebase structure and inventory |
| `/quantdev:debug` | Root cause analysis for trading bugs |
| `/quantdev:quick` | One-off tasks |
| `/quantdev:help` | Command reference |
| `/quantdev:doctor` | Health-check diagnostic |
| `/quantdev:s` | Alias for `/quantdev:status` |
| `/quantdev:q` | Alias for `/quantdev:quick` |

## Skills (Auto-Activating)

Quantdev includes 13 skills that activate automatically when trigger conditions match:

| Skill | When It Activates |
|-------|-------------------|
| `quantdev-tdd` | Writing new indicator/bot code |
| `quantdev-debugging` | Errors, test failures, signal mismatch |
| `quantdev-verification` | Before claiming task is complete |
| `lookahead-guard` | Indicator or signal code written/reviewed |
| `regime-awareness` | Strategy design, backtest analysis, optimization |
| `cross-platform-consistency` | Indicator code changes on any platform |
| `risk-discipline` | Bot code, position sizing, order logic |
| `backtest-integrity` | Backtest results analysis |
| `git-workflow` | Branch management, commits, delivery |
| `parallel-dispatch` | 2+ independent tasks that can run concurrently |
| `documentation` | After indicator/bot/research work |
| `lessons-learned` | After validation, post-backtest |
| `using-quantdev` | Every session (skill discovery protocol) |

## Agents

Quantdev dispatches 11 specialized agents for different phases of work:

| Agent | Role | Default Model | Dispatched By |
|-------|------|---------------|---------------|
| **Strategy Architect** | Strategy logic design, indicator composition, regime-aware reasoning | opus | `/quantdev:indicator`, `/quantdev:bot` |
| **Builder** | Indicator/bot code with TDD, cross-platform implementation | sonnet | `/quantdev:indicator`, `/quantdev:bot`, `/quantdev:port`, `/quantdev:deploy` |
| **Reviewer** | Two-stage review: trading correctness + code quality | sonnet | `/quantdev:indicator`, `/quantdev:bot`, `/quantdev:review` |
| **Strategy Verifier** | Two-stage verification: code-level + empirical statistical | sonnet | `/quantdev:bot`, `/quantdev:backtest` |
| **Backtester** | Go backtest engine orchestration and results analysis | sonnet/haiku | `/quantdev:backtest` |
| **Optimizer** | Parameter sweeps, sensitivity analysis, overfitting detection | sonnet | `/quantdev:optimize` |
| **Quant Researcher** | Statistical analysis, regime detection, academic review | opus | `/quantdev:research` |
| **Risk Analyst** | Position sizing, drawdown modeling, portfolio risk | opus | `/quantdev:risk`, `/quantdev:optimize` |
| **Cross-Platform Validator** | Golden-file comparison across platform implementations | haiku | `/quantdev:validate` |
| **Debugger** | Root-cause analysis with 5 Whys protocol | sonnet/opus | `/quantdev:debug` |
| **Documenter** | Strategy journals, knowledge base, parameter docs | sonnet | `/quantdev:indicator`, `/quantdev:bot` |

## Platform Tiers

| Tier | Platforms | Role |
|------|-----------|------|
| **Tier 1** | Go, Python | Source of truth for math. Backtesting engine. Live bots. |
| **Tier 2** | Pine Script | Primary charting platform. Most prolific indicator library. |
| **Tier 3** | NinjaScript C#, Tradovate JS | Port when needed. Secondary priority. |

## Project State Structure

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

## Configuration

When you run `/quantdev:init`, quantdev creates a `.quantdev/config.json` in your project:

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

## Stack

- **Historical Data**: Databento (manual downloads to local CSV/Parquet)
- **Live Data**: TopStepX connection
- **Execution**: Apex API direct
- **Markets**: US futures, ET session times
- **Backtesting**: Go engine
- **Bots**: Python 3.11+ with async

## Agent Teams Support

Quantdev supports [Claude Code Agent Teams](https://docs.anthropic.com/en/docs/claude-code) — an experimental feature where multiple independent Claude Code instances collaborate on the same project.

When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set, multi-agent commands (`/quantdev:indicator`, `/quantdev:bot`, `/quantdev:map`) prompt you to choose between team mode (parallel teammates via TeamCreate) and agent mode (standard Task subagents). Teammate detection uses `CLAUDE_CODE_TEAM_NAME` automatically.

See [docs/AGENT-TEAMS-GUIDE.md](docs/AGENT-TEAMS-GUIDE.md) for the full guide.

## Plugin Structure

```
quantdev/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── agents/                     # 11 agent dispatch prompts
│   ├── architect.md
│   ├── backtester.md
│   ├── builder.md
│   ├── cross-platform-validator.md
│   ├── debugger.md
│   ├── documenter.md
│   ├── optimizer.md
│   ├── researcher.md
│   ├── reviewer.md
│   ├── risk-analyst.md
│   └── verifier.md
├── commands/                   # 22 slash command definitions
│   ├── backtest.md
│   ├── bot.md
│   ├── debug.md
│   ├── deploy.md
│   ├── doctor.md
│   ├── help.md
│   ├── indicator.md
│   ├── init.md
│   ├── map.md
│   ├── optimize.md
│   ├── port.md
│   ├── q.md
│   ├── quick.md
│   ├── recover.md
│   ├── research.md
│   ├── resume.md
│   ├── review.md
│   ├── risk.md
│   ├── rollback.md
│   ├── s.md
│   ├── status.md
│   └── validate.md
├── skills/                     # 13 auto-activating skills
│   ├── backtest-integrity/
│   ├── cross-platform-consistency/
│   ├── documentation/
│   ├── git-workflow/
│   ├── lessons-learned/
│   ├── lookahead-guard/
│   ├── parallel-dispatch/
│   ├── quantdev-debugging/
│   ├── quantdev-tdd/
│   ├── quantdev-verification/
│   ├── regime-awareness/
│   ├── risk-discipline/
│   └── using-quantdev/
├── hooks/
│   ├── hooks.json              # 5 hooks: SessionStart, TeammateIdle, TaskCompleted, Stop
│   ├── teammate-idle.sh
│   ├── task-completed.sh
│   └── stop.sh
├── scripts/
│   ├── state-read.sh
│   ├── state-write.sh
│   ├── team-detect.sh
│   ├── checkpoint.sh
│   ├── check-versions.sh
│   └── marketplace-sync.sh
├── test/                       # bats test suite
├── docs/
│   ├── AGENT-GUIDE.md
│   ├── AGENT-TEAMS-GUIDE.md
│   ├── PROTOCOLS.md
│   └── QUICKSTART.md
├── CHANGELOG.md
├── LICENSE
├── README.md
└── package.json
```

## License

MIT
