---
description: "Initialize quantdev project — configure data paths, platforms, execution stack, and trading preferences"
disable-model-invocation: true
argument-hint: "[--fresh] — start over with a fresh .quantdev/ directory"
---

# /quantdev:init - Trading Project Initialization

You are executing the quantdev initialization workflow. This configures a trading development environment with data paths, platform tiers, execution stack, and session settings. Follow these steps precisely and in order.

<prerequisites>

## Step 1: Check Existing State

Check if a `.quantdev/` directory already exists in the current project root.

- **If it exists AND `.quantdev/config.json` exists:** Tell the user:
  > "Project already initialized. Run `/quantdev:init --fresh` to start over."
  Then stop.

- **If `--fresh` flag is provided:** Require explicit confirmation from the user before proceeding. If confirmed, rename `.quantdev/` to `.quantdev-archive-{YYYY-MM-DD}/` and create a fresh `.quantdev/` directory. If not confirmed, stop.

- **If `.quantdev/` does not exist:** Create the `.quantdev/` directory and proceed to Step 2.

## Step 2: Lightweight Project Detection

Determine whether this is a **brownfield** (existing trading code) or **greenfield** (new project) by checking for:
- Go source files (`*.go`, `go.mod`)
- Python source files (`*.py`, `requirements.txt`, `pyproject.toml`)
- Pine Script files (`*.pine`)
- NinjaScript files (`*.cs` in indicator/strategy paths)
- Existing data directories (`data/`, `data/GLBX/`)
- Existing bot or indicator code

This is only used to tailor next-steps guidance in Step 5 — no full codebase analysis is performed.

</prerequisites>

<execution>

## Step 3: Collect Settings

Collect workflow preferences from the user using three `AskUserQuestion` calls. Each call stays within the 4-question limit. Wait for the user's answers before proceeding to the next batch.

### Batch 1: Data & Platforms

Use `AskUserQuestion` with these 4 questions:

1. **Historical data path** — "Where is your historical market data stored?"
   - `data/GLBX/ (Recommended)` — Databento manual downloads in local directory.
   - `Custom path` — Specify a different data directory.

2. **Data formats** — "What formats is your historical data in?"
   - `CSV (Recommended)` — Standard CSV bar data.
   - `Parquet` — Columnar format for larger datasets.
   - `Both CSV and Parquet` — Mixed formats.

3. **Platform tiers** — "Which platform configuration should quantdev use?"
   - `Standard (Recommended)` — Tier 1: Go + Python. Tier 2: Pine Script. Tier 3: NinjaScript, Tradovate.
   - `Go-focused` — Tier 1: Go only. Tier 2: Pine Script. Tier 3: Python, NinjaScript, Tradovate.
   - `Python-focused` — Tier 1: Python only. Tier 2: Pine Script. Tier 3: Go, NinjaScript, Tradovate.

4. **Execution stack** — "What is your execution/brokerage setup?"
   - `Apex API direct (Recommended)` — Direct API connection to Apex for futures trading.
   - `Paper only` — No live execution. Backtesting and research only.

### Batch 2: Session & Workflow

Use `AskUserQuestion` with these 4 questions:

5. **Session timezone** — "What timezone do you trade in?"
   - `America/New_York (ET) (Recommended)` — US Eastern. Standard for US futures.
   - `America/Chicago (CT)` — US Central.
   - `UTC` — Universal Coordinated Time.

6. **Git tracking** — "How should quantdev create commits?"
   - `Per task (Recommended)` — Atomic commit after each completed task. Easy to review and revert.
   - `Per phase` — Batch changes into one commit per phase. Cleaner history.
   - `Manual` — quantdev won't commit. You control all git operations.

7. **Review depth** — "How thorough should review gates be?"
   - `Detailed (Recommended)` — Two-stage review (trading correctness + code quality).
   - `Lightweight` — Quick verification only. Faster but catches fewer issues.

8. **Knowledge base** — "Should quantdev maintain a knowledge base of strategy findings?"
   - `Yes (Recommended)` — Accumulates market knowledge, backtest findings, and lessons learned in KNOWLEDGE.md.
   - `No` — Skip knowledge base. Strategy journals still maintained per-strategy.

### Batch 3: Model & Risk Preferences

Use `AskUserQuestion` with these 3 questions:

9. **Model routing** — "Which model routing strategy should quantdev use for its agents?"
   - `Adaptive (Recommended)` — Opus for strategy design/risk. Sonnet for building/review. Haiku for validation. Balances cost and quality.
   - `All Sonnet` — Use Sonnet for everything. Good balance of speed and capability.
   - `All Opus` — Use Opus for everything. Maximum quality, highest cost.

10. **Default risk limits** — "What default risk limits should apply to new strategies?"
    - `Conservative (Recommended)` — 1% per trade, 3% daily max loss. Suitable for prop firm rules.
    - `Moderate` — 2% per trade, 5% daily max loss.
    - `Custom` — Configure custom limits.

11. **Context loading** — "How much project context should quantdev load at session start?"
    - `Auto (Recommended)` — Adjusts based on current state (minimal when idle, full during execution).
    - `Minimal` — Always load minimal context. Fastest startup, less awareness.
    - `Full` — Always load everything including knowledge base. Slowest startup, maximum awareness.

## Step 4: Write Configuration & State

After collecting all answers, write the following files:

### config.json

Write `.quantdev/config.json` with the user's choices:

```json
{
  "platforms": {
    "tier1": ["go", "python"],
    "tier2": ["pinescript"],
    "tier3": ["ninjatrader", "tradovate"]
  },
  "data": {
    "historical_path": "data/GLBX",
    "formats": ["csv"],
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
  "risk_defaults": {
    "per_trade_risk_pct": 1.0,
    "daily_max_loss_pct": 3.0,
    "max_concurrent_positions": 2
  },
  "git_strategy": "per_task",
  "review_depth": "detailed",
  "knowledge_base": true,
  "model_routing": "adaptive",
  "context_tier": "auto",
  "created_at": "{ISO timestamp}",
  "version": "1.0"
}
```

Map the user's answers to the appropriate config values. Use the defaults shown above for any unanswered or skipped fields.

### Directory Structure

Create the `.quantdev/` directory structure:
```
.quantdev/
├── config.json
├── STATE.json
├── HISTORY.md
├── KNOWLEDGE.md          (if knowledge_base: true)
├── strategies/
├── research/
├── validation/
│   └── golden/
└── quick/
```

### STATE.json & HISTORY.md

Follow **State Update Protocol** (update `.quantdev/STATE.json` and `.quantdev/HISTORY.md` via state-write.sh; see `docs/PROTOCOLS.md`) -- create initial state:
- **Phase:** 1
- **Position:** Initialization complete, ready for work
- **Status:** ready
- **Message:** `Project initialized`

### Commit

```bash
git add .quantdev/
git commit -m "quantdev: initialize trading project"
```

</execution>

<output>

## Step 5: Guided Next Steps

Display contextual guidance based on brownfield/greenfield detection from Step 2:

**Brownfield (existing trading code):**
> Project initialized! Here's what to do next:
>
> - `/quantdev:map` — Analyze your existing trading codebase (recommended first step)
> - `/quantdev:indicator` — Design and build a new indicator
> - `/quantdev:bot` — Build a trading bot
> - `/quantdev:quick` — Quick one-off task
>
> Your configuration is in `.quantdev/config.json`.

**Greenfield (new project):**
> Project initialized! Here's what to do next:
>
> - `/quantdev:indicator` — Design and build your first indicator
> - `/quantdev:bot` — Build a trading bot (templates available: keltner, supertrend, ema, vwap, alligator)
> - `/quantdev:research` — Start with quant research
> - `/quantdev:quick` — Quick one-off task
>
> Your configuration is in `.quantdev/config.json`.

</output>
