---
description: "Root cause analysis for trading bugs — session boundaries, bar alignment, indicator divergence"
disable-model-invocation: true
argument-hint: "<error description or test name>"
---

# /quantdev:debug - Trading Bug Investigation

You are executing the quantdev debugging workflow. This dispatches a dedicated debugger agent for systematic root-cause investigation with trading-specific context. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

- If an error description is provided, use it as the problem statement.
- If no argument is provided, ask the user:
  > "What issue are you investigating? Provide the error message, failing test, or describe the unexpected behavior."

## Step 2: Gather Context

1. Read `.quantdev/STATE.json` if it exists (for current strategy context)
2. Read `.quantdev/config.json` for model routing and session configuration
3. Read `.quantdev/KNOWLEDGE.md` if it exists (for known issues and patterns)
4. Follow **Worktree Protocol** (detect if running in a git worktree; see `docs/PROTOCOLS.md`)
5. Follow **Model Routing Protocol** (select the correct model for the debugger role using `model_routing.debugging` from config; see `docs/PROTOCOLS.md`)

</prerequisites>

<execution>

## Step 3: Dispatch Debugger

Dispatch a **Debugger agent** (subagent_type: "quantdev:debugger") following the **Model Routing Protocol** with:
- The problem statement (error description, test name, or unexpected behavior)
- Working directory, current branch, and worktree status
- Codebase docs per **Codebase Docs Protocol** (see `docs/PROTOCOLS.md`)
- `.quantdev/PROJECT.md` if it exists
- `.quantdev/KNOWLEDGE.md` if it exists (check for known similar issues)
- Session configuration from config (timezone, RTH hours, overnight)
- Recent git log (`git log --oneline -20`)
- Any error output or stack traces the user provided

The debugger agent performs:

1. **Root cause investigation** with trading-specific checks:
   - **Session boundaries:** Does the bug occur at RTH open/close? At overnight session transitions? At the initial balance boundary?
   - **Timezone conversion:** Are times being compared in the same timezone? Is ET used consistently? Daylight saving transitions?
   - **Bar alignment:** Are bars aligned to expected boundaries? Off-by-one in bar indexing? First bar of session handling?
   - **Data gaps:** Missing bars, holiday gaps, early close days, partial sessions?
   - **Indicator divergence:** Does the same indicator produce different values on different platforms? Which platform diverged and starting at which bar?
   - **Backtest vs live discrepancy:** Different fill logic? Different data source? Session time differences?

2. **Pattern analysis:** Compare working vs broken code, check recent commits for regressions

3. **Hypothesis testing:** Minimal changes, one variable at a time

4. **Remediation plan:** Documented steps for the fix

## Step 4: Present Results

Read the debugger's output and present to the user:
- Root cause summary
- Evidence chain (with trading-specific context)
- Remediation plan

</execution>

<output>

## Step 5: Route Forward

Offer the user options based on the diagnosis:

- **Fix now:** "Run `/quantdev:quick {remediation summary}` to implement the fix."
- **Validate fix:** "After fixing, run `/quantdev:validate {indicator}` to verify cross-platform consistency."
- **Re-backtest:** "Run `/quantdev:backtest {strategy}` to confirm the fix doesn't change expected behavior (or changes it in the expected way)."
- **Manual fix:** "The remediation plan is documented above. Fix it yourself and run the verification command to confirm."

If the root cause is a known pattern (e.g., session boundary bug, timezone issue), suggest adding it to the knowledge base:
> "This is a common trading bug pattern. Add to KNOWLEDGE.md for future reference? (y/n)"

</output>
