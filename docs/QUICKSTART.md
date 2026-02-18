# Quantdev Quickstart

Quantdev is a Claude Code plugin for systematic trading development. It manages the full lifecycle of trading indicators, bots, and quantitative research across multiple platforms (Go, Python, Pine Script, NinjaScript, Tradovate JS).

## I Want To...

### Build and Test Indicators
| Situation | Command |
|-----------|---------|
| Design and build a new indicator | `/quantdev:indicator` |
| Port indicator to another platform | `/quantdev:port` |
| Validate cross-platform consistency | `/quantdev:validate` |

### Develop Trading Bots
| Situation | Command |
|-----------|---------|
| Create a new trading bot | `/quantdev:bot` |
| Generate deployment configs | `/quantdev:deploy` |
| Use a bot template | `/quantdev:bot --template keltner` |

### Research and Backtest
| Situation | Command |
|-----------|---------|
| Run a backtest | `/quantdev:backtest` |
| Optimize parameters | `/quantdev:optimize` |
| Research a strategy hypothesis | `/quantdev:research` |

### Review and Analyze
| Situation | Command |
|-----------|---------|
| Review trading code | `/quantdev:review` |
| Analyze risk parameters | `/quantdev:risk` |
| Debug a trading bug | `/quantdev:debug` |

### Project Management
| Situation | Command |
|-----------|---------|
| Set up a new project | `/quantdev:init` |
| Check status | `/quantdev:status` |
| Resume previous session | `/quantdev:resume` |
| Analyze codebase structure | `/quantdev:map` |
| Quick one-off task | `/quantdev:quick "task description"` |

## Common Workflows

### New Indicator Development
```
/quantdev:indicator "Keltner Channel with ATR filter"
  → Strategy Architect designs indicator math and golden-file tests
  → Builder implements in Go (source of truth)
  → Reviewer checks for lookahead bias and correctness
  → Cross-Platform Validator compares against golden reference

/quantdev:port "Keltner to Pine Script"
  → Builder translates Go implementation to Pine Script
  → Reviewer validates platform-specific idioms

/quantdev:validate "Keltner"
  → Cross-Platform Validator compares all implementations
```

### New Bot Creation
```
/quantdev:bot "EMA Crossover"
  → Strategy Architect designs entry/exit logic and risk parameters
  → Builder implements in Python or Go following platform naming conventions
  → Reviewer checks trading correctness (lookahead, fills, risk)
  → Strategy Verifier runs integrity checklist and empirical tests

/quantdev:deploy "EMA Crossover"
  → Builder generates Docker/systemd configs (no live execution)
```

### Strategy Research and Optimization
```
/quantdev:research "regime detection for mean reversion"
  → Quant Researcher conducts statistical analysis
  → Findings added to knowledge base

/quantdev:backtest "SuperTrend"
  → Backtester orchestrates Go engine against local data
  → Analyzes profit factor, Sharpe, drawdown, trade distribution
  → Strategy Verifier checks for overfitting flags

/quantdev:optimize "SuperTrend --param atr_period"
  → Optimizer runs parameter sweeps
  → Detects robust plateaus vs brittle peaks
  → Risk Analyst validates position sizing
```

### Pre-Deploy Review
```
/quantdev:review src/bots/vwap/
  → Reviewer performs two-stage review:
    Stage 1: Trading correctness (lookahead, sessions, fills)
    Stage 2: Code quality and patterns

/quantdev:risk "VWAP Reversal"
  → Risk Analyst validates position sizing
  → Models drawdown scenarios
  → Validates Apex margin requirements
```

## Model Routing

Quantdev routes each agent to an appropriate model tier based on task complexity:

| Agent | Default Model | Config Key | Best For |
|-------|--------------|------------|----------|
| **Strategy Architect** | Opus | `architecture` | Novel strategy design, regime-aware logic |
| **Quant Researcher** | Opus | `planning` | Statistical analysis, academic review |
| **Risk Analyst** | Opus | `security_audit` | Position sizing, drawdown modeling |
| **Builder** | Sonnet | `building` | Implementing indicators, bots, tests |
| **Reviewer** | Sonnet | `review` | Two-stage code review |
| **Strategy Verifier** | Sonnet | `validation` | Integrity checklist + empirical tests |
| **Optimizer** | Sonnet | `simplification` | Parameter sweeps, sensitivity |
| **Backtester** | Sonnet | `debugging` | Backtest orchestration (Haiku for runs) |
| **Debugger** | Sonnet | `debugging` | Root cause analysis (Opus for complex) |
| **Documenter** | Sonnet | `documentation` | Strategy journals, knowledge base |
| **Cross-Platform Validator** | Haiku | `mapping` | Fast golden-file comparison |

**Override defaults** in `.quantdev/config.json`:
```json
{
  "model_routing": {
    "architecture": "opus",
    "building": "sonnet",
    "review": "sonnet",
    "security_audit": "opus",
    "debugging": "opus"
  }
}
```

Upgrade `security_audit` to Opus for complex risk analysis. Upgrade `debugging` to Opus for multi-platform bugs.

## Three Tracks

### Indicator Track
Build, port, and validate technical indicators across platforms.

**Pipeline:** Strategy Architect → Builder → Reviewer → Cross-Platform Validator

**Commands:** `/quantdev:indicator`, `/quantdev:port`, `/quantdev:validate`

**Platforms:** Go (Tier 1 source of truth), Python (Tier 1), Pine Script (Tier 2 primary charting), NinjaScript C# (Tier 3), Tradovate JS (Tier 3)

### Bot Track
Design, build, test, and prepare trading bots for deployment.

**Pipeline:** Strategy Architect → Builder → Reviewer → Strategy Verifier

**Commands:** `/quantdev:bot`, `/quantdev:deploy`

**Deliverable:** Docker/systemd configs, never executes live trades

### Research Track
Backtest orchestration, parameter optimization, statistical validation.

**Pipeline:** Backtester → Strategy Verifier, Optimizer → Risk Analyst

**Commands:** `/quantdev:backtest`, `/quantdev:optimize`, `/quantdev:research`, `/quantdev:risk`

**Data:** Local CSV/Parquet files (Databento) in `data/GLBX/`, live via TopStepX, execution via Apex API

## Tips

- **Use platform naming conventions** — each platform has specific naming standards (PascalCase in Go/C#, camelCase in Pine Script/JS, snake_case in Python). No custom suffixes.
- **Session awareness is critical** — RTH 09:30-16:00 ET, IB 09:30-10:30 ET, OVN 18:00-09:30 ET
- **Lookahead bias kills strategies** — Reviewer and Strategy Verifier check every implementation
- **Cross-platform validation catches drift** — Run `/quantdev:validate` after indicator changes
- **Risk parameters are mandatory** — Every bot needs max daily loss, per-trade risk, stop loss, position limits
- **Backtesting flags overfitting** — Sharpe > 3, win rate > 75%, < 30 trades, smooth equity all trigger warnings
- **Knowledge base accumulates findings** — `.quantdev/KNOWLEDGE.md` captures market observations and lessons learned
- **Most commands work without init** — `/quantdev:review`, `/quantdev:debug`, `/quantdev:map` run on any codebase
- **Quick tasks get full pipeline** — `/quantdev:quick` still includes TDD, review, and atomic commits
