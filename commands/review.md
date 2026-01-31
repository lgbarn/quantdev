---
description: "On-demand code review with trading-specific correctness checks"
disable-model-invocation: true
argument-hint: "[target] — file, diff range (main..HEAD), or current (default: uncommitted changes)"
---

# /quantdev:review - On-Demand Trading Code Review

You are executing an on-demand code review with trading-specific correctness checks. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `target` (optional): What to review. Accepts:
  - **No argument / "current"**: Review uncommitted changes (`git diff` + `git diff --cached`)
  - **Diff range** (e.g., `main..HEAD`, `abc123..def456`): Review commits in range
  - **File/directory path**: Review current state of specific files
  - **Branch name**: Review branch changes vs main (`main..<branch>`)

If no target and no uncommitted changes exist, ask the user what they want reviewed.

## Step 2: Detect Context

1. Check if `.quantdev/` exists (optional — this command works anywhere).
2. If `.quantdev/config.json` exists, read `model_routing` for model selection and `sessions` for timezone context.
3. Otherwise, use default model: **sonnet**.
4. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

</prerequisites>

<execution>

## Step 3: Gather Diff

Based on the target, collect the code to review:
- **Current**: `git diff` + `git diff --cached`
- **Range**: `git diff <range>` + `git log --oneline <range>`
- **Path**: `git diff HEAD -- <path>` (or read files directly if untracked)
- **Branch**: `git diff main...<branch>`

If the diff is empty, inform the user and stop.

## Step 4: Build Agent Context

Assemble context per **Agent Context Protocol** (see `docs/PROTOCOLS.md`):
- The diff content collected in Step 3
- `.quantdev/PROJECT.md` (if exists) — for project understanding
- `.quantdev/KNOWLEDGE.md` (if exists) — for accumulated trading knowledge
- Codebase docs per **Codebase Docs Protocol** (if `.quantdev/` exists)
- Working directory, current branch, and worktree status
- Session configuration (timezone, RTH hours) for validating session boundary handling

## Step 5: Dispatch Reviewer

Dispatch a **Reviewer agent** (subagent_type: "quantdev:reviewer") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.review` (default: sonnet)
- max_turns: 20
- All context from Step 4
- Instruction: Perform two-stage review with trading focus.

  **Stage 1 — Trading Correctness:**
  - **Lookahead bias:** Does the code access future data? Use `Close` of a bar that hasn't completed? Index `[0]` where `[1]` (last completed bar) is correct?
  - **Session boundary handling:** Does the code handle RTH open/close correctly? Overnight session transitions? What happens at session boundaries for indicators with state?
  - **Fill assumptions:** Are limit orders assumed to fill at the exact limit price? Is slippage modeled or at least configurable? Are commissions accounted for?
  - **Bar alignment:** Are bars aligned to session boundaries? Is there off-by-one in bar indexing? Are warmup periods handled correctly?
  - **Data gaps:** How does the code handle missing bars, holidays, early closes?
  - **Risk parameters:** Are risk limits enforced? Is position sizing bounded? Are stops present on every entry?
  - **Timezone correctness:** Are times compared in the same timezone? Is ET session time used consistently?

  **Stage 2 — Code Quality:**
  - Pattern consistency with existing codebase
  - Naming conventions (LB conventions)
  - Test coverage
  - Error handling
  - Platform-specific idioms (Go table-driven tests, Pine Script `barstate`, etc.)

</execution>

<output>

## Step 6: Present Results

Display the review report to the user.

If findings exist, offer follow-up:
> "Would you like me to:
> - Fix the critical/important issues
> - Review additional files or a different scope
> - `/quantdev:validate {indicator}` — Run cross-platform validation if indicator changes detected
> - `/quantdev:debug {issue}` — Investigate a specific finding in depth"

</output>
