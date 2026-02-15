---
description: "Orchestrate Go backtest engine against local historical data"
disable-model-invocation: true
argument-hint: "<strategy-name> [--data path] [--params file] [--period 2024-01-01:2024-12-31]"
---

# /quantdev:backtest - Backtest Orchestration

You are executing the quantdev backtest workflow. This orchestrates the Go backtest engine against local CSV/Parquet data, analyzes results, and verifies integrity. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `strategy-name` (REQUIRED): The strategy to backtest.
- `--data` (optional): Path to historical data. Default: read from `config.json` → `data.historical_path` (typically `data/GLBX/`).
- `--params` (optional): Path to parameter override file (JSON). Default: use `.quantdev/strategies/{strategy-name}/PARAMS.json`.
- `--period` (optional): Date range in `YYYY-MM-DD:YYYY-MM-DD` format. Default: all available data.

If no strategy name is provided, ask the user:
> "Which strategy would you like to backtest? Provide the strategy name."

## Step 2: Detect Context

1. Check if `.quantdev/` exists. Read `config.json` for data paths, session config, and model routing.
2. Locate the strategy: check codebase and `.quantdev/strategies/{strategy-name}/`.
3. If strategy not found:
   > "Strategy '{strategy-name}' not found. Run `/quantdev:bot {strategy-name}` to build it first."
   Stop here.
4. Verify historical data exists at the configured path.
5. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Load Parameters

Read parameters in order of precedence:
1. `--params` file if specified
2. `.quantdev/strategies/{strategy-name}/PARAMS.json`
3. Defaults from the strategy implementation

Display the parameter set to the user for confirmation:
> "Running backtest with these parameters: {param list}. Proceed? (y/n)"

</prerequisites>

<execution>

## Step 4: Backtester — Run the Engine

Dispatch a **Backtester agent** (subagent_type: "quantdev:backtester") with:
- Follow **Model Routing Protocol** — resolve model (default: sonnet for analysis, haiku for individual runs)
- max_turns: 20
- The strategy name and implementation path
- Data path and file format (CSV/Parquet)
- Parameter set
- Date range (if specified)
- Session config from `.quantdev/config.json` (timezone, RTH, overnight hours)
- Instruction: Execute the Go backtest engine and analyze results.
  1. Run the backtest with the specified parameters
  2. Collect and analyze metrics:
     - **Profit factor** (gross profit / gross loss)
     - **Sharpe ratio** (annualized, risk-free rate = current T-bill)
     - **Max drawdown** (absolute and %, duration, recovery time)
     - **Win rate** (% of profitable trades)
     - **Average win/loss ratio**
     - **Trade count** (total, longs, shorts)
     - **Trade distribution** by time of day, day of week
     - **Equity curve** characteristics
  3. Compare against existing baselines if `.quantdev/strategies/{strategy-name}/backtests/` has prior results
  4. Write results to `.quantdev/strategies/{strategy-name}/backtests/{timestamp}.json`

## Step 5: Strategy Verifier — Check Integrity

Dispatch a **Strategy Verifier agent** (subagent_type: "quantdev:verifier") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.verification` (default: sonnet)
- max_turns: 15
- The backtest results from Step 4
- Instruction: Stage 2 empirical verification. Flag:
  - **Overfitting signals:** Sharpe > 3, win rate > 75%, equity curve suspiciously smooth
  - **Insufficient sample:** < 30 trades, < 6 months of data
  - **No OOS testing:** Results are in-sample only
  - **Unrealistic fills:** All trades filled at exact limit price, no slippage
  - **Survivorship bias:** Strategy only tested on recent data

## Step 6: Post-Backtest Integrity Check

After backtest completion, run the integrity check script:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-backtest.sh"
```
This will:
- Auto-flag suspicious metrics (Sharpe > 3, win rate > 75%, PF > 4, < 30 trades)
- Write findings to the strategy journal
- Report severity level (OK, WARNING, CRITICAL)

## Step 7: Update State & Commit

1. Save results to `.quantdev/strategies/{strategy-name}/backtests/{timestamp}.json`
2. Update strategy journal `.quantdev/strategies/{strategy-name}/JOURNAL.md` with backtest entry
3. Follow **State Update Protocol** (see `docs/PROTOCOLS.md`)
4. Create atomic git commit: `test({strategy-name}): backtest results {date-range}`

</execution>

<output>

## Step 8: Report

Display backtest results:
```
Backtest Results: {strategy-name}
═══════════════════════════════════════════
Period: {start} to {end}
Data: {data-path}
Parameters: {key params summary}

Performance Metrics:
  Profit Factor:     {PF}
  Sharpe Ratio:      {Sharpe}
  Max Drawdown:      {DD%} (${DD-abs})
  Win Rate:          {WR%}
  Avg Win/Loss:      {ratio}
  Total Trades:      {N} (L: {longs}, S: {shorts})

Integrity Check:     {PASS|WARNINGS}
{list any flags}

Comparison vs Baseline: {better|worse|first-run}
```

Suggest next steps:
> - `/quantdev:optimize {strategy-name}` — Find better parameters via sweep
> - `/quantdev:risk {strategy-name}` — Position sizing based on these results
> - `/quantdev:backtest {strategy-name} --period {OOS-range}` — Out-of-sample test

</output>
