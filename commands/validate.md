---
description: "Cross-platform golden-file comparison for indicator implementations"
disable-model-invocation: true
argument-hint: "<indicator-name> [--tolerance 0.0001]"
---

# /quantdev:validate - Cross-Platform Validation

You are executing the quantdev cross-platform validation workflow. This compares indicator outputs across all platform implementations against golden reference data. Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `indicator-name` (REQUIRED): The indicator to validate.
- `--tolerance` (optional): Maximum acceptable divergence (epsilon). Default: `0.0001`.

If no indicator name is provided, ask the user:
> "Which indicator would you like to validate? Provide the indicator name."

## Step 2: Detect Context

1. Check if `.quantdev/` exists. If not:
   > "No quantdev project found. Run `/quantdev:init` first, or ensure `.quantdev/validation/golden/` contains reference data."
   Stop here.
2. Read `.quantdev/config.json` for platform tiers and model routing.
3. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

## Step 3: Locate Implementations

Scan for indicator implementations across platforms:
- **Go:** Look in standard Go source paths for the indicator package/file
- **Python:** Look for indicator module/file
- **Pine Script:** Look for `.pine` files
- **NinjaScript:** Look for `.cs` indicator files
- **Tradovate:** Look for `.js` indicator files
- Also check `.quantdev/strategies/{indicator-name}/indicators/` for organized implementations

If fewer than 2 implementations are found:
> "Only {N} implementation(s) found for {indicator-name}. Cross-platform validation requires at least 2. Use `/quantdev:port` to create additional implementations."
Stop here.

## Step 4: Locate or Generate Golden Data

Check `.quantdev/validation/golden/{indicator-name}/`:
- If golden reference data exists, use it.
- If not, inform the user:
  > "No golden reference data found. The validator will use the Go implementation as the reference (Tier 1 source of truth) and generate golden files."

</prerequisites>

<execution>

## Step 5: Dispatch Cross-Platform Validator

Dispatch a **Cross-Platform Validator agent** (subagent_type: "quantdev:validator") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.validation` (default: haiku)
- max_turns: 15
- The indicator name and tolerance threshold
- Paths to all discovered implementations
- Golden reference data path (or instruction to generate from Go implementation)
- Instruction: For each platform implementation:
  1. Run the indicator with identical inputs from the golden data set
  2. Collect outputs (all output series/values)
  3. Compute per-bar absolute difference against the reference
  4. Flag any bar where divergence exceeds the tolerance epsilon
  5. Report: which platform diverged, on which bar(s), by how much
  6. If no golden data exists, run the Go implementation first to generate it, then compare others

## Step 6: Save Results

Write validation results to `.quantdev/validation/{indicator-name}-{timestamp}.json`:
```json
{
  "indicator": "{name}",
  "timestamp": "{ISO}",
  "tolerance": 0.0001,
  "reference": "go",
  "platforms_tested": ["go", "python", "pinescript"],
  "results": {
    "python": { "status": "pass", "max_divergence": 0.0000001, "bars_tested": 500 },
    "pinescript": { "status": "fail", "max_divergence": 0.0023, "divergent_bars": [142, 143, 144], "bars_tested": 500 }
  }
}
```

</execution>

<output>

## Step 7: Report

Display validation results:
```
Cross-Platform Validation: {indicator-name}
═══════════════════════════════════════════
Reference: Go implementation
Tolerance: {epsilon}

Platform        Status    Max Divergence    Bars Tested
─────────────────────────────────────────────────────────
Go (ref)        PASS      —                 {N}
Python          PASS      0.0000001         {N}
Pine Script     FAIL      0.0023            {N}
  └─ Divergent bars: 142-144 (session boundary)

Overall: {PASS|FAIL}
```

If failures exist, suggest:
> "Validation failed for {platforms}. Recommended actions:"
> - `/quantdev:debug {indicator-name} divergence on {platform}` — Investigate the divergence
> - `/quantdev:port {source-file} {platform}` — Re-port from the reference implementation

If all pass:
> "All platforms within tolerance. Results saved to `.quantdev/validation/`."

</output>
