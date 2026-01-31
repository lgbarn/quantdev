---
description: "Restore context from a previous trading session and continue"
disable-model-invocation: true
argument-hint: ""
---

# /quantdev:resume - Session Restoration

You are executing the quantdev resume workflow. Follow these steps precisely.

<prerequisites>

## Step 1: Verify State Exists

Check if `.quantdev/` directory exists.

- **If it does not exist:**
  Display:
  > "No quantdev project found. Nothing to resume. Run `/quantdev:init` to start a new project."
  Stop here.

## Step 2: Read Last Position

Follow **State Loading Protocol** (read STATE.json, HISTORY.md, PROJECT.md, config.json, and recent artifacts to establish session context; see `docs/PROTOCOLS.md`) -- read STATE.json for current track, strategy, position, and HISTORY.md for history.

</prerequisites>

<execution>

## Step 3: Detect Incomplete Work

Scan `.quantdev/strategies/` and `.quantdev/research/` for signs of incomplete work:

**Indicator work was interrupted if:**
- HYPOTHESIS.md exists but no implementation files
- Implementation exists but no tests or tests failing
- Some platforms implemented but validation never ran

**Bot work was interrupted if:**
- HYPOTHESIS.md exists but no bot implementation
- Implementation exists but no backtest results
- Backtest ran but no review or verification

**Research was interrupted if:**
- Research directory exists with partial FINDINGS.md
- Backtest started but no results file
- Optimization started but no results

**Optimization was interrupted if:**
- Partial sweep results exist
- Sweep complete but no risk analysis

Document what was in progress and what remains.

## Step 4: Reconstruct Context

Build a context summary by reading (in order):
1. `.quantdev/PROJECT.md` -- overall trading system goals
2. `.quantdev/config.json` -- platform tiers, data paths, session config
3. `.quantdev/KNOWLEDGE.md` -- accumulated market knowledge
4. The most recent strategy journals (`.quantdev/strategies/*/JOURNAL.md`)
5. Recent backtest results and optimization data
6. The last entries in HISTORY.md

Synthesize this into a brief context restoration message:
```
## Session Restored

**Active Track:** {Indicator|Bot|Research}
**Strategy:** {name or N/A}
**Last Action:** {description from HISTORY.md}
**Incomplete Work:**
- {list of what was in progress}

**Key Context:**
- {2-3 most important recent findings or decisions}
```

## Step 5: Recreate Native Tasks

Follow **Native Task Scaffolding Protocol** (see `docs/PROTOCOLS.md`) -- check if native tasks exist (via TaskList), and recreate from strategy artifacts if missing or stale.

## Step 6: Display Status Overview

Run the same display logic as `/quantdev:status` (Display Trading Dashboard step from status.md):
- Show active strategies and their state
- Show recent backtest results
- Show pending validations
- Show knowledge base stats

</execution>

<output>

## Step 7: Route to Next Action

Based on where work was interrupted, suggest the specific next step:

| Interrupted During | Resume Action |
|-------------------|---------------|
| Indicator design | `/quantdev:indicator {name}` (restart design) |
| Indicator implementation | `/quantdev:indicator {name}` (resume build) |
| Cross-platform porting | `/quantdev:port {file} {platform}` (continue porting) |
| Bot design | `/quantdev:bot {name}` (restart design) |
| Bot implementation | `/quantdev:bot {name}` (resume build) |
| Backtest execution | `/quantdev:backtest {name}` (re-run) |
| Parameter optimization | `/quantdev:optimize {name}` (re-run sweep) |
| Risk analysis | `/quantdev:risk {name}` (re-run analysis) |
| Research | `/quantdev:research {topic}` (continue research) |
| Validation | `/quantdev:validate {name}` (re-run validation) |

Present clearly:
> "**Session restored.** You were {doing X} when the session ended. Run `{command}` to continue."

</output>
