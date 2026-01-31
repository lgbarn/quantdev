---
description: "Parameter sweeps and sensitivity analysis for trading strategies"
disable-model-invocation: true
argument-hint: "<strategy-name> [--param name --range min:max:step] [--method grid|walk-forward]"
---

# /quantdev:optimize - Parameter Optimization

You are executing the quantdev parameter optimization workflow. This runs parameter sweeps using Go optimize tooling, detects overfitting, and validates robustness. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `strategy-name` (REQUIRED): The strategy to optimize.
- `--param` (optional, repeatable): Parameter name to sweep. Can be specified multiple times.
- `--range` (optional): Range for each param in `min:max:step` format (paired with `--param`).
- `--method` (optional): Optimization method. Default: `grid`. Valid: `grid`, `walk-forward`.

If no strategy name is provided, ask the user:
> "Which strategy would you like to optimize? Provide the strategy name."

## Step 2: Detect Context

1. Read `.quantdev/config.json` for data paths and model routing.
2. Locate strategy and its `PARAMS.json` for current defaults and valid ranges.
3. If no params specified, read `PARAMS.json` for parameters with defined ranges.
4. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Confirm Sweep Configuration

If no `--param` flags were provided, present discoverable parameters:
> "Parameters available for optimization:"
> - `atr_period` (current: 14, range: 5-50, step: 1)
> - `atr_multiplier` (current: 2.0, range: 0.5-5.0, step: 0.25)
> - `adx_threshold` (current: 25, range: 15-40, step: 5)
>
> "Which parameters should be swept? Select or provide custom ranges."

Display total combinations and estimated run time:
> "Sweep: {N} parameter combinations × {M} bars = ~{estimate}"

</prerequisites>

<execution>

## Step 4: Optimizer — Run Sweeps

Dispatch an **Optimizer agent** (subagent_type: "quantdev:optimizer") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.optimization` (default: sonnet)
- max_turns: 25
- The strategy name and implementation path
- Parameter sweep configuration (names, ranges, steps)
- Optimization method (grid or walk-forward)
- Data path and session config
- Instruction:
  1. **Grid sweep:** Run backtest for every parameter combination. Record: profit factor, Sharpe, max drawdown, trade count for each.
  2. **Walk-forward (if selected):** Split data into rolling in-sample/out-of-sample windows. Optimize on in-sample, test on out-of-sample. Report IS vs OOS performance decay.
  3. **Sensitivity analysis:** For each parameter, measure how much the key metrics change per unit change. Identify:
     - **Robust plateaus:** Parameter regions where performance is stable (good — strategy works across a range)
     - **Brittle peaks:** Narrow parameter values where performance drops sharply outside (bad — likely overfit)
  4. **Correlation analysis:** Check if parameters are correlated (e.g., ATR period and multiplier may have offsetting effects).
  5. Write results to `.quantdev/strategies/{strategy-name}/optimization/{timestamp}/`

## Step 5: Risk Analyst — Validate Optimal Parameters

Dispatch a **Risk Analyst agent** (subagent_type: "quantdev:risk-analyst") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.risk` (default: opus)
- max_turns: 15
- The optimization results from Step 4
- Instruction: Validate the risk characteristics of the optimal parameter set.
  - Does the optimal set produce acceptable drawdown?
  - Is position sizing still within risk limits?
  - How does the worst-case scenario compare to account constraints?
  - Are the optimal parameters on a robust plateau or a brittle peak?

## Step 6: Update State & Commit

1. Save results to `.quantdev/strategies/{strategy-name}/optimization/{timestamp}/`
2. If user approves new parameters, update `PARAMS.json` with optimization results
3. Update strategy journal with optimization entry
4. Follow **State Update Protocol** (see `docs/PROTOCOLS.md`)
5. Create atomic git commit: `perf({strategy-name}): parameter optimization {method}`

</execution>

<output>

## Step 7: Report

Display optimization results:
```
Parameter Optimization: {strategy-name}
═══════════════════════════════════════════
Method: {grid|walk-forward}
Combinations tested: {N}

Top 5 Parameter Sets:
  #  ATR Period  ATR Mult  ADX Thresh  |  PF    Sharpe  MaxDD   Trades
  1  14          2.5       20          |  2.8   1.9     -8.2%   142
  2  12          2.5       20          |  2.7   1.8     -9.1%   156
  3  14          2.0       25          |  2.6   1.7     -7.5%   128
  ...

Sensitivity Analysis:
  ATR Period:     ROBUST (plateau 10-18, stable PF)
  ATR Multiplier: MODERATE (2.0-3.0 acceptable, sharp drop below 1.5)
  ADX Threshold:  ROBUST (15-30 all perform similarly)

Risk Assessment: {PASS|CAUTION}
{risk analyst findings}
```

Suggest next steps:
> - Apply the recommended parameters? (updates PARAMS.json)
> - `/quantdev:backtest {strategy-name} --period {OOS}` — Out-of-sample validation with new params
> - `/quantdev:risk {strategy-name}` — Full risk analysis with optimized parameters

</output>
