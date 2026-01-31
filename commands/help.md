---
description: "Show help for quantdev commands organized by track"
disable-model-invocation: true
argument-hint: "[topic]"
---

# /quantdev:help - Command Reference

You are executing the quantdev help command. Follow these steps precisely.

<execution>

## Step 1: Check for Topic Argument

If a topic argument was provided (e.g., `/quantdev:help bot`), skip to Step 3.

If no argument was provided, show the default quick-reference table (Step 2).

## Step 2: Default — Command Reference by Track

Display this table:

```
quantdev — Trading Development Plugin
═══════════════════════════════════════════

INDICATOR TRACK
  /quantdev:indicator <name>       Design and build a new indicator
  /quantdev:validate <name>        Cross-platform golden-file comparison
  /quantdev:port <file> <platform> Translate indicator between platforms

BOT TRACK
  /quantdev:bot <name>             Full bot creation pipeline (templates: keltner, supertrend, ema, vwap, alligator)
  /quantdev:deploy <name>          Generate deployment configs (Docker, systemd)

RESEARCH TRACK
  /quantdev:backtest <name>        Orchestrate Go backtest engine
  /quantdev:optimize <name>        Parameter sweeps and sensitivity analysis
  /quantdev:research <topic>       Regime analysis, statistical tests, academic review

QUALITY GATES
  /quantdev:review [target]        Code review with trading correctness checks
  /quantdev:risk <name>            Position sizing, drawdown modeling, portfolio risk

UTILITY
  /quantdev:map [focus]            Analyze trading codebase structure
  /quantdev:debug <error>          Root cause analysis for trading bugs
  /quantdev:quick <task>           One-off task execution
  /quantdev:status                 Trading dashboard

LIFECYCLE
  /quantdev:init                   Initialize project (data paths, platforms, risk)
  /quantdev:resume                 Restore previous session context
  /quantdev:recover                Diagnose and fix state issues
  /quantdev:rollback               Revert to a checkpoint
  /quantdev:doctor                 Plugin health check

Aliases: /quantdev:s (status), /quantdev:q (quick)
```

Then display:

> "For detailed help on a specific command, run `/quantdev:help <topic>`."
> "Example: `/quantdev:help bot` or `/quantdev:help backtest`"

Stop here.

## Step 3: Topic-Specific Help

Match the topic argument to a command or concept:

### Command Topics

| Topic | Help |
|-------|------|
| `init` | `/quantdev:init` — Configure data paths, platform tiers, execution stack, session times, risk limits. Creates `.quantdev/` directory. |
| `indicator` | `/quantdev:indicator <name> [--platforms go,python,pinescript]` — Strategy Architect designs the math → Builder implements per platform → Reviewer checks for trading bugs. |
| `validate` | `/quantdev:validate <name> [--tolerance 0.0001]` — Cross-Platform Validator runs each implementation with identical inputs, computes differences, flags divergence. |
| `port` | `/quantdev:port <source-file> <target-platform>` — Builder writes the port → Reviewer verifies mathematical consistency. Platforms: go, python, pinescript, ninjatrader, tradovate. |
| `bot` | `/quantdev:bot <name> [--template keltner\|supertrend\|ema\|vwap\|alligator] [--lang go\|python]` — Full pipeline: Strategy Architect designs → Builder implements → Reviewer reviews → Strategy Verifier validates. |
| `deploy` | `/quantdev:deploy <name> [--format docker\|systemd\|all]` — Generates Dockerfile, docker-compose.yml, systemd unit, .env template. NEVER executes live trades. |
| `backtest` | `/quantdev:backtest <name> [--data path] [--params file] [--period start:end]` — Backtester runs Go engine → analyzes metrics → Strategy Verifier checks integrity. |
| `optimize` | `/quantdev:optimize <name> [--param name --range min:max:step] [--method grid\|walk-forward]` — Optimizer runs sweeps → Risk Analyst validates risk characteristics. |
| `research` | `/quantdev:research <topic>` — Quant Researcher: regime analysis, statistical significance, academic literature, market microstructure, walk-forward design. |
| `review` | `/quantdev:review [target]` — Two-stage: trading correctness (lookahead, sessions, fills, slippage) + code quality. |
| `risk` | `/quantdev:risk <name> [--account-size N] [--max-daily-loss N]` — Position sizing (fractional, Kelly, prop firm), drawdown modeling (Monte Carlo), correlation analysis. |
| `map` | `/quantdev:map [focus]` — Focus: indicators, strategies, backtests, coverage (or all). Maps trading codebase inventory. |
| `debug` | `/quantdev:debug <error>` — 5-Whys with trading context: session boundaries, timezone, bar alignment, data gaps, indicator divergence, backtest vs live. |
| `quick`, `q` | `/quantdev:quick <task>` — Architect + builder for small tasks. |
| `status`, `s` | `/quantdev:status` — Dashboard: active strategies, recent backtests, pending validations, knowledge base stats. |
| `resume` | `/quantdev:resume` — Restore context from a previous session. |
| `recover` | `/quantdev:recover` — Diagnose and fix state inconsistencies. |
| `rollback` | `/quantdev:rollback [tag] [--list]` — Revert to a checkpoint. |
| `doctor` | `/quantdev:doctor` — Check plugin health and dependencies. |
| `help` | `/quantdev:help [topic]` — This help command. |

### Concept Topics

| Topic | Help |
|-------|------|
| `platforms` | **Platform Tiers:** Tier 1 (Go, Python) = source of truth, backtesting, live. Tier 2 (Pine Script) = charting. Tier 3 (NinjaScript, Tradovate) = secondary. |
| `templates` | **Bot Templates:** keltner (PF 10.04), ema (PF 6.23), vwap (PF 5.20), supertrend (PF 4.41), alligator (PF 4.16). Use `--template` with `/quantdev:bot`. |
| `tracks` | **Three Tracks:** Indicator (design/port/validate indicators), Bot (design/build/test/deploy bots), Research (backtest/optimize/analyze). |
| `knowledge` | **Knowledge Base:** `.quantdev/KNOWLEDGE.md` accumulates market findings, strategy lessons, and research conclusions. Updated automatically. |
| `sessions` | **Session Times (ET):** RTH 09:30-16:00, Initial Balance 09:30-10:30, Overnight 18:00-09:30. Configured in `.quantdev/config.json`. |
| `tdd` | **TDD for Trading:** Indicators: golden-file tests. Bots: behavioral tests ("long when X AND Y"). Strategies: regression baselines. |
| `lookahead` | **Lookahead Bias:** Never access future data. Use `[1]` (last completed bar), not `[0]` (current bar). Don't use Close during an open bar. |

For the matched topic, display:
1. The command/concept name and description
2. Usage syntax with arguments
3. 2-3 common usage examples

If the topic doesn't match anything, display:
> "Unknown topic: '{topic}'. Run `/quantdev:help` to see all available commands."

</execution>
