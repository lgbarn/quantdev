---
description: "Quantitative research — regime analysis, statistical tests, academic review, market microstructure"
disable-model-invocation: true
argument-hint: "<topic> — required: regime analysis, statistical test, market research, or walk-forward design"
---

# /quantdev:research - Quantitative Research

You are executing quantitative research. This dispatches the Quant Researcher for statistical analysis, regime detection, academic literature review, and market microstructure investigation. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `topic` (REQUIRED): The research topic. Examples:
  - `"regime detection for ES futures"` — Regime analysis
  - `"is my keltner strategy overfit?"` — Statistical significance testing
  - `"ADX vs directional movement for trend detection"` — Indicator comparison
  - `"microstructure of initial balance breakouts"` — Market microstructure
  - `"walk-forward design for parameter optimization"` — Walk-forward analysis
  - `"academic literature on mean reversion in futures"` — Literature review

If no topic is provided, ask the user what they want to research.

## Step 2: Detect Context

1. Check if `.quantdev/` exists (optional — this command works anywhere).
2. If `.quantdev/config.json` exists, read `model_routing` for model selection.
3. Otherwise, use default model: **opus** (research benefits from deep reasoning).
4. Read `.quantdev/KNOWLEDGE.md` if it exists — for context on prior findings.
5. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

</prerequisites>

<execution>

## Step 3: Build Agent Context

Assemble context per **Agent Context Protocol** (see `docs/PROTOCOLS.md`):
- The research topic from Step 1
- `.quantdev/PROJECT.md` (if exists) — for trading system context
- `.quantdev/KNOWLEDGE.md` (if exists) — for accumulated findings
- Codebase docs per **Codebase Docs Protocol** (if `.quantdev/` exists)
- Available backtest results in `.quantdev/strategies/*/backtests/` (if relevant)
- Working directory and current branch

## Step 4: Dispatch Quant Researcher

Dispatch a **Quant Researcher agent** (subagent_type: "quantdev:researcher") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.research` (default: opus)
- max_turns: 25
- All context from Step 3
- Instruction: Investigate the topic with quantitative rigor. Based on topic type:

  **Regime Analysis:**
  - Analyze historical data for market regime patterns (trending, ranging, volatile)
  - Identify regime indicators (ADX, volatility ratio, Hurst exponent)
  - Segment backtest results by regime if strategy data available
  - Recommend regime filters for strategy improvement

  **Statistical Significance:**
  - Is the strategy's edge statistically significant? (t-test, bootstrap)
  - Sample size assessment: enough trades for reliable conclusions?
  - In-sample vs out-of-sample comparison
  - Monte Carlo analysis: could random trading produce similar results?
  - Parameter stability: does performance degrade with small parameter changes?

  **Academic Literature Review:**
  - Search for relevant academic papers and quantitative finance research
  - Summarize key findings and methodologies
  - Assess applicability to the user's trading context
  - Identify potential pitfalls or contradictory evidence

  **Market Microstructure:**
  - Analyze order flow, liquidity patterns, session dynamics
  - Initial balance behavior, gap analysis, volume profiles
  - Time-of-day effects, day-of-week patterns
  - Implications for strategy design and execution

  **Walk-Forward Design:**
  - Recommend in-sample/out-of-sample window sizes
  - Anchored vs rolling vs expanding window tradeoffs
  - Number of walk-forward steps for statistical validity
  - Metrics to track across walk-forward windows

  Write findings to `.quantdev/research/{topic-slug}/FINDINGS.md`

</execution>

<output>

## Step 5: Present Results & Update Knowledge

Display the research findings to the user.

If `.quantdev/KNOWLEDGE.md` exists, offer:
> "Would you like me to:
> - Add key findings to the knowledge base (KNOWLEDGE.md)
> - Save this research to `.quantdev/research/` for future reference
> - Design a strategy based on these findings (`/quantdev:bot`)
> - Run a backtest to validate a hypothesis (`/quantdev:backtest`)
> - Research a related topic"

</output>
