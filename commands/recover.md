---
description: "Diagnose and recover from interrupted or corrupted trading state"
disable-model-invocation: true
argument-hint: ""
---

# /quantdev:recover - State Recovery

You are executing the quantdev recovery workflow. Follow these steps precisely.

<prerequisites>

## Step 1: Verify State Exists

Check if `.quantdev/` directory exists.

- **If it does not exist:**
  > "No quantdev project detected. Nothing to recover. Run `/quantdev:init` to start fresh."
  Stop here.

</prerequisites>

<execution>

## Step 2: Diagnose State

Follow **State Loading Protocol** (read STATE.json, HISTORY.md, PROJECT.md, config.json, and recent artifacts to establish session context; see `docs/PROTOCOLS.md`) -- read STATE.json, HISTORY.md, config.json, and strategy artifacts. Then check for inconsistencies:

### Check for these inconsistencies:

| Symptom | Diagnosis |
|---------|-----------|
| STATE.json references a strategy that doesn't exist in `strategies/` | State and artifacts are out of sync |
| STATE.json is missing or empty | State file was corrupted or deleted |
| Strategy directory exists but HYPOTHESIS.md is missing | Strategy design was interrupted |
| Backtest results reference a strategy with no implementation | Orphaned backtest data |
| PARAMS.json references parameters not in the implementation | Parameter drift after optimization |
| Validation results exist for a deleted indicator | Stale validation data |
| KNOWLEDGE.md references strategies that no longer exist | Knowledge base needs cleanup |

## Step 3: List Available Checkpoints

Run `git tag -l "quantdev-checkpoint-*" --sort=-version:refname` and identify the most recent checkpoint.

## Step 4: Present Diagnosis

Display a clear diagnosis:

```
Recovery Diagnosis
══════════════════

State: {description of what STATE.json says}
Actual: {description of what artifacts exist}
Problem: {what is inconsistent}
Last checkpoint: {most recent checkpoint tag, or "none"}

Recommended action: {see options below}
```

</execution>

<output>

## Step 5: Present Recovery Options

Based on the diagnosis, present these options (in order of preference):

### Option 1: Resume from current state
> "Continue from where things stopped. Run `/quantdev:resume` to restore context and pick up."

**Best when:** Build was interrupted cleanly, some work was completed and committed.

### Option 2: Rollback to last checkpoint
> "Revert to the last known good state. Run `/quantdev:rollback`."

**Best when:** State is corrupted or inconsistent, but a recent checkpoint exists.

### Option 3: Reset state file
> "Rebuild STATE.json from existing artifacts. This examines what plans, summaries, and reviews exist and reconstructs the state to match reality."

**Best when:** STATE.json is corrupted or out of sync, but the actual artifacts (.quantdev/ plans, summaries) are intact.

If the user selects this option:
1. Scan `.quantdev/strategies/` for all strategy directories with artifacts
2. Check each strategy's state from artifacts (HYPOTHESIS.md, implementation, backtests, optimization)
3. Rebuild STATE.json to reflect actual progress:
   ```json
   {
     "last_updated": "<timestamp>",
     "active_track": "{derived from most recent artifacts}",
     "active_strategy": "{most recently modified strategy}",
     "status": "{derived from artifacts}"
   }
   ```
4. Append recovery entry to HISTORY.md: `- [<timestamp>] State recovered from artifacts`
5. Commit: `quantdev: recover state from artifacts`

### Option 4: Full reset
> "Archive current state and start fresh. This moves `.quantdev/` to `.quantdev-archive-<timestamp>/` and allows `/quantdev:init` to run again."

**Best when:** State is severely corrupted and no checkpoint is usable.

**Require explicit confirmation:**
> "This will archive all quantdev state including strategy data, backtest results, and knowledge base. Type 'RESET' to confirm."

</output>
