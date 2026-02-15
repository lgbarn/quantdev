---
description: "Check quantdev plugin health and trading dependencies"
disable-model-invocation: true
argument-hint: ""
---

# /quantdev:doctor — Plugin Health Check

You are executing the quantdev doctor diagnostic. Follow these steps precisely.

<execution>

## Step 1: Check Dependencies

Run each check and record pass/fail:

```bash
# 1. jq installed
command -v jq >/dev/null 2>&1 && echo "PASS: jq found ($(jq --version))" || echo "FAIL: jq not found — install with: brew install jq (macOS) or apt install jq (Linux)"

# 2. git installed
command -v git >/dev/null 2>&1 && echo "PASS: git found ($(git --version))" || echo "FAIL: git not found"

# 3. gh CLI (optional)
command -v gh >/dev/null 2>&1 && echo "PASS: gh found ($(gh --version | head -1))" || echo "INFO: gh not found — optional, needed for PR workflows"
```

## Step 2: Check Plugin Structure

Verify the quantdev plugin files are intact:

```bash
# Check plugin root has expected files
PLUGIN_ROOT="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/.." && pwd)"
```

Verify these exist:
- `.claude-plugin/plugin.json` — Plugin manifest
- `hooks/` — Hook scripts directory
- `scripts/` — Script files
- `skills/` — Skill definitions
- `commands/` — Command definitions

Report any missing items.

## Step 3: Check Skills Discoverable

```bash
# Count discoverable skills
skill_count=$(find skills/ -name "SKILL.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
echo "Skills discovered: ${skill_count}"
```

List all discovered skills by name.

## Step 4: Check Hooks Registered

Read `.claude-plugin/plugin.json` and verify hooks are defined:
- `SessionStart` hook → `scripts/state-read.sh`
- `PreToolUse` hooks (if any)
- `PostToolUse` hooks (if any)

Verify each hook script file exists and is executable.

## Step 5: Check Trading Dependencies

```bash
# Go toolchain (Tier 1 — required for backtesting engine)
command -v go >/dev/null 2>&1 && echo "PASS: go found ($(go version | awk '{print $3}'))" || echo "WARN: go not found — required for backtesting engine and Tier 1 indicators"

# Python (Tier 1)
command -v python3 >/dev/null 2>&1 && echo "PASS: python3 found ($(python3 --version 2>&1 | awk '{print $2}'))" || echo "WARN: python3 not found — required for Tier 1 indicators and bots"
```

## Step 6: Check Project State (if .quantdev/ exists)

If `.quantdev/` exists:
- Verify `.quantdev/` is NOT a symlink
- Check `STATE.json` exists and is valid JSON
- Check `config.json` exists and is valid JSON with required fields (`platforms`, `data`, `sessions`)
- Check `HISTORY.md` exists
- Check `strategies/` directory exists
- Check `validation/golden/` directory exists
- If `config.json` has `knowledge_base: true`, check `KNOWLEDGE.md` exists
- Report any missing or corrupt files

If `.quantdev/` does not exist:
> "No quantdev project in current directory. Run `/quantdev:init` to set up."

</execution>

<output>

## Step 7: Summary Report

Display results:

```
quantdev Doctor
═══════════════════════════════════════════

Core Dependencies:
  jq           {PASS|FAIL}
  git          {PASS|FAIL}
  gh           {PASS|INFO: optional}

Trading Dependencies:
  go           {PASS|WARN: needed for backtesting}
  python3      {PASS|WARN: needed for Tier 1}

Plugin Structure:
  .claude-plugin/plugin.json  {PASS|FAIL}
  hooks/       {PASS|FAIL}
  scripts/     {PASS|FAIL}
  skills/      {PASS|FAIL} ({N} skills)
  commands/    {PASS|FAIL} ({N} commands)

Hooks:
  SessionStart {PASS|FAIL}

Project State:
  .quantdev/       {PASS|NOT FOUND|CORRUPT}
  STATE.json       {PASS|MISSING|CORRUPT}
  config.json      {PASS|MISSING}
  strategies/      {PASS|MISSING}
  validation/      {PASS|MISSING}
  KNOWLEDGE.md     {PASS|MISSING|N/A}

Result: {All checks passed | N issues found}
```

If any FAIL results, provide specific remediation steps.

</output>
