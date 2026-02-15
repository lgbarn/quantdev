# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-02-14

Initial release of quantdev — a Claude Code plugin for systematic trading development.

### Added

#### Agents (11)
- **Strategy Architect**: Strategy logic design, indicator composition, regime-aware reasoning (Opus)
- **Builder**: Indicator/bot code with TDD, cross-platform implementation (Sonnet)
- **Reviewer**: Two-stage review for trading correctness and code quality (Sonnet)
- **Strategy Verifier**: Two-stage verification with code-level and empirical statistical analysis (Sonnet)
- **Backtester**: Go backtest engine orchestration and results analysis (Sonnet/Haiku adaptive)
- **Optimizer**: Parameter sweeps, sensitivity analysis, overfitting detection (Sonnet)
- **Quant Researcher**: Statistical analysis, regime detection, academic review (Opus)
- **Risk Analyst**: Position sizing, drawdown modeling, portfolio risk (Opus)
- **Cross-Platform Validator**: Golden-file comparison across platform implementations (Haiku)
- **Debugger**: Root-cause analysis with 5 Whys protocol (Sonnet/Opus adaptive)
- **Documenter**: Strategy journals, knowledge base entries, parameter documentation (Sonnet)

#### Commands (22)
- **Lifecycle**: init, status, resume, recover, rollback
- **Indicator Track**: indicator, validate, port
- **Bot Track**: bot, deploy
- **Research Track**: backtest, optimize, research
- **Quality Gates**: review, risk
- **Utility**: map, debug, quick, help, doctor, s (status alias), q (quick alias)

#### Skills (13)
- **Trading-Specific (5)**: lookahead-guard, regime-awareness, cross-platform-consistency, risk-discipline, backtest-integrity
- **Adapted from Shipyard (7)**: quantdev-tdd, quantdev-debugging, quantdev-verification, git-workflow, parallel-dispatch, documentation, lessons-learned
- **Meta**: using-quantdev (skill discovery protocol)

#### Hooks (5)
- **SessionStart**: Adaptive context loading (light for quick tasks, full for research)
- **TeammateIdle**: Quality gate for agent teams (version check + test pass)
- **TaskCompleted**: Track-specific evidence verification
- **PostBacktest**: Auto-flags overfitting signals (Sharpe > 3, win rate > 75%, < 30 trades, smooth equity curve)
- **Stop**: State persistence and in-progress work tracking

#### Infrastructure
- Project state structure (`.quantdev/` with strategies/, research/, validation/, quick/)
- Trading-specific config.json schema (platforms, data, execution, sessions, model_routing)
- Platform tier system (Go/Python tier 1, Pine Script tier 2, NinjaScript/Tradovate tier 3)
- Agent Teams support with automatic detection via `CLAUDE_CODE_TEAM_NAME` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- State file locking for concurrent writes in teams mode
- Knowledge base system (KNOWLEDGE.md, strategy journals, findings)
- Golden-file validation framework for cross-platform consistency
- Adaptive model routing (Opus for deep reasoning, Sonnet for standard work, Haiku for fast validation)
- BATS test suite
- Strategy-focused documentation (AGENT-GUIDE.md, AGENT-TEAMS-GUIDE.md, PROTOCOLS.md, QUICKSTART.md)
