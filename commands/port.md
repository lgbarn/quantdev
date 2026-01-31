---
description: "Translate an indicator between trading platforms"
disable-model-invocation: true
argument-hint: "<source-file> <target-platform> — platforms: go, python, pinescript, ninjatrader, tradovate"
---

# /quantdev:port - Cross-Platform Indicator Port

You are executing the quantdev indicator porting workflow. This translates an indicator from one platform to another while preserving mathematical consistency. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `source-file` (REQUIRED): Path to the source indicator file to port from.
- `target-platform` (REQUIRED): Target platform. One of: `go`, `python`, `pinescript`, `ninjatrader`, `tradovate`.

If arguments are missing, ask the user:
> "Provide the source file and target platform. Example: `/quantdev:port indicators/keltner.go pinescript`"

## Step 2: Detect Source Platform

Identify the source platform from the file extension and content:
- `.go` → Go
- `.py` → Python
- `.pine` → Pine Script
- `.cs` (with NinjaScript patterns like `OnBarClose`) → NinjaScript C#
- `.js` (with Tradovate patterns like `module.exports`, `init`/`next`) → Tradovate JS

Validate: source and target must be different platforms.

## Step 3: Detect Context

1. Read the source file to understand the indicator logic.
2. If `.quantdev/config.json` exists, read model routing configuration.
3. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

</prerequisites>

<execution>

## Step 4: Builder — Write the Port

Dispatch a **Builder agent** (subagent_type: "quantdev:builder") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.building` (default: sonnet)
- max_turns: 30
- The source file content
- Source platform identification
- Target platform and its conventions:
  - **Go:** Table-driven `_test.go` tests, exported types, godoc comments
  - **Python:** pytest, type hints, numpy/pandas for vectorized operations
  - **Pine Script:** `indicator()` header, `input.*()` for parameters, `plot()` for outputs, `barstate.*` for session awareness
  - **NinjaScript C#:** `OnBarClose()` lifecycle, `AddPlot()`, `ISeries<double>`, `OnStateChange()` state machine
  - **Tradovate JS:** `module.exports = { init(), map(), filter() }`, `d.close()` data access
- Instruction:
  1. Write a failing test first (golden-file pattern using the same test data as the source)
  2. Port the indicator preserving exact mathematical behavior
  3. Handle platform-specific idioms: warmup periods, session boundaries, null/NaN values
  4. Ensure parameter names and defaults match the source
  5. Run tests to confirm pass

## Step 5: Reviewer — Verify Mathematical Consistency

Dispatch a **Reviewer agent** (subagent_type: "quantdev:reviewer") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.review` (default: sonnet)
- max_turns: 15
- The source file and the ported file
- Instruction: Verify mathematical consistency between source and port.
  - **Stage 1 — Math equivalence:** Compare formulas line by line. Check for floating-point order-of-operations differences. Verify warmup period handling matches. Check edge cases (first bar, session open, data gaps).
  - **Stage 2 — Platform correctness:** Verify the port follows target platform idioms correctly. Check for common porting bugs: incorrect bar indexing, missing session boundary handling, wrong data access patterns.

If issues found, send back to Builder for fixes and re-review.

## Step 6: Commit

Create atomic git commit:
```
feat({indicator-name}): port to {target-platform} from {source-platform}
```

</execution>

<output>

## Step 7: Report & Next Steps

Display:
```
Port Complete: {indicator-name}
Source: {source-file} ({source-platform})
Target: {target-file} ({target-platform})
Tests: {pass/fail}
```

Suggest next steps:
> - `/quantdev:validate {indicator-name}` — Run cross-platform validation to confirm consistency
> - `/quantdev:port {source-file} {another-platform}` — Port to additional platforms

</output>
