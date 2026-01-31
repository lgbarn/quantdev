---
description: "Position sizing, drawdown modeling, and portfolio risk analysis"
disable-model-invocation: true
argument-hint: "<strategy-name> [--account-size N] [--max-daily-loss N]"
---

# /quantdev:risk - Risk Analysis

You are executing the quantdev risk analysis workflow. This performs position sizing analysis, drawdown modeling, correlation analysis, and portfolio-level risk assessment. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `strategy-name` (REQUIRED): The strategy to analyze. Use `portfolio` to analyze all active strategies together.
- `--account-size` (optional): Account size in dollars. Default: read from config or ask user.
- `--max-daily-loss` (optional): Max daily loss limit in dollars. Default: read from config or ask user.

If no strategy name is provided, ask the user:
> "Which strategy needs risk analysis? Provide the strategy name, or use `portfolio` for all active strategies."

## Step 2: Detect Context

1. Read `.quantdev/config.json` for execution stack (Apex constraints) and session config.
2. Locate strategy backtest results in `.quantdev/strategies/{strategy-name}/backtests/`.
3. If no backtest results exist:
   > "No backtest results found for '{strategy-name}'. Run `/quantdev:backtest {strategy-name}` first — risk analysis requires historical performance data."
   Stop here.
4. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Collect Account Constraints

If not provided via arguments, ask the user:

Use `AskUserQuestion` with 2 questions:

1. **Account size** — "What is the account size for risk calculations?"
   - `$50,000 (Apex PA)` — Standard Apex performance account
   - `$150,000 (Apex PA)` — Large Apex performance account
   - `$25,000 (small)` — Smaller account
   - (Custom via "Other")

2. **Risk tolerance** — "What is your maximum acceptable daily loss?"
   - `2% of account (Recommended)` — Conservative, suitable for prop firm rules
   - `3% of account` — Moderate
   - `5% of account` — Aggressive
   - (Custom via "Other")

</prerequisites>

<execution>

## Step 4: Risk Analyst — Full Analysis

Dispatch a **Risk Analyst agent** (subagent_type: "quantdev:risk-analyst") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.risk` (default: opus)
- max_turns: 20
- The strategy name and backtest results (most recent + any prior results for comparison)
- Account size and risk tolerance from Step 3
- Execution constraints (Apex account rules if applicable)
- If `portfolio` mode, include all active strategy backtest results
- Instruction: Produce a comprehensive risk report covering:

### Position Sizing Analysis
  - **Fixed fractional:** Recommended position size based on risk per trade
  - **Kelly criterion:** Optimal fraction (and half-Kelly for safety)
  - **Prop firm constraints:** Position size limits for Apex accounts (margin requirements, max contracts)
  - **Recommendation:** Suggested position size with rationale

### Drawdown Modeling
  - **Historical max drawdown:** From backtest data
  - **Monte Carlo simulation:** 10,000 random trade sequences → drawdown distribution
  - **Recovery time:** Expected time to recover from max drawdown scenarios
  - **Underwater periods:** Longest consecutive losing streak and capital impact
  - **Daily P&L distribution:** Probability of hitting daily max loss

### Correlation Analysis (portfolio mode)
  - **Strategy correlation matrix:** Pairwise correlation of equity curves
  - **Diversification benefit:** Combined portfolio drawdown vs individual
  - **Concentration risk:** What % of portfolio risk comes from each strategy

### Risk Parameter Validation
  - Is the daily max loss limit realistic given the strategy's characteristics?
  - Are per-trade risk limits enforced in the code?
  - Is position size within exchange/account limits?
  - Are there adequate stops on every position?

Write report to `.quantdev/strategies/{strategy-name}/risk-report-{timestamp}.md`

## Step 5: Update State & Commit

1. Save risk report
2. Update strategy journal with risk analysis entry
3. Follow **State Update Protocol** (see `docs/PROTOCOLS.md`)
4. Create atomic git commit: `docs({strategy-name}): risk analysis report`

</execution>

<output>

## Step 6: Report

Display risk analysis summary:
```
Risk Analysis: {strategy-name}
═══════════════════════════════════════════
Account: ${account-size}
Max Daily Loss: ${max-daily-loss} ({%})

Position Sizing:
  Fixed Fractional (2% risk):  {N} contracts
  Kelly Criterion:             {N} contracts (half-Kelly: {N/2})
  Apex Limit:                  {N} contracts
  → Recommended:               {N} contracts

Drawdown Modeling:
  Historical Max DD:           ${amount} ({%})
  Monte Carlo 95th %ile DD:    ${amount} ({%})
  Expected Recovery Time:      {N} trading days
  Max Losing Streak:           {N} trades (${impact})

Daily P&L Risk:
  Prob(daily loss > max):      {%}
  Expected daily P&L range:    -${loss} to +${gain}

Overall Risk Rating: {CONSERVATIVE|MODERATE|AGGRESSIVE|EXCESSIVE}
```

Suggest next steps:
> - `/quantdev:deploy {strategy-name}` — Generate deployment configs with these risk parameters
> - `/quantdev:optimize {strategy-name}` — Re-optimize if risk is excessive
> - `/quantdev:backtest {strategy-name} --params {adjusted-params}` — Retest with adjusted sizing

</output>
