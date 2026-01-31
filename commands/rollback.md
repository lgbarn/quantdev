---
description: "Revert to a previous quantdev checkpoint"
disable-model-invocation: true
argument-hint: "[checkpoint-tag] [--list]"
---

# /quantdev:rollback - Checkpoint Rollback

You are executing the quantdev rollback workflow. Follow these steps precisely.

<prerequisites>

## Step 1: Verify State

1. Verify `.quantdev/` exists. If not, tell the user there is nothing to roll back.
2. Verify this is a git repository with at least one commit.

## Step 2: List Checkpoints

Run `git tag -l "quantdev-checkpoint-*" --sort=-version:refname` to find all checkpoints.

- **If `--list` was passed**, display checkpoints with dates and labels, then stop.
- **If no checkpoints exist**, inform the user:
  > "No quantdev checkpoints found. Checkpoints are created automatically during `/quantdev:indicator`, `/quantdev:bot`, and `/quantdev:backtest`."

</prerequisites>

<execution>

## Step 3: Select Checkpoint

- **If a specific checkpoint tag was provided**, use it. Verify it exists with `git tag -l`.
- **If no argument**, show the 5 most recent checkpoints and ask the user to select one:

```
Available Checkpoints
═════════════════════

1. quantdev-checkpoint-post-build-phase-2-20260131T...
2. quantdev-checkpoint-pre-build-phase-2-20260131T...
3. quantdev-checkpoint-post-plan-phase-2-20260130T...
4. quantdev-checkpoint-post-build-phase-1-20260130T...
5. quantdev-checkpoint-pre-build-phase-1-20260130T...

Select a checkpoint (1-5):
```

## Step 4: Choose Rollback Scope

Ask the user:

> "What scope should the rollback cover?"
> 1. **State only** — Revert `.quantdev/` files only (plans, state, roadmap). Code stays as-is.
> 2. **Full rollback** — Revert both `.quantdev/` state AND code changes back to the checkpoint.

## Step 5: Create Safety Checkpoint

Before any rollback, create a safety checkpoint:

Follow **Checkpoint Protocol** (create a named git tag for rollback safety at key pipeline stages; see `docs/PROTOCOLS.md`) -- create `pre-rollback` checkpoint.

This ensures the current state can be recovered if the rollback was a mistake.

## Step 6: Execute Rollback

### State-only rollback:

```bash
git checkout <checkpoint-tag> -- .quantdev/
```

This restores all `.quantdev/` files to their state at the checkpoint without affecting code.

### Full rollback:

Identify all commits between the checkpoint and HEAD:

```bash
git log --oneline <checkpoint-tag>..HEAD
```

Show the user what will be reverted. Then:

```bash
git revert --no-commit <checkpoint-tag>..HEAD
git commit -m "quantdev: rollback to <checkpoint-tag>"
```

## Step 7: Update State

Add a history entry to `.quantdev/HISTORY.md`:

```
- [<timestamp>] Rolled back to <checkpoint-tag> (<scope>)
```

</execution>

<output>

## Step 8: Confirm

Display:
> "Rollback complete. Reverted to `<checkpoint-tag>` (<scope> scope)."
> "Safety checkpoint created: `quantdev-checkpoint-pre-rollback-<timestamp>`"
> "Run `/quantdev:status` to see current state."

</output>
