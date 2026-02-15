---
name: lessons-learned
description: Use when capturing discoveries after phase completion, before shipping, or when reflecting on completed work to extract reusable patterns
---

<!-- TOKEN BUDGET: 155 lines / ~465 tokens -->

# Lessons Learned

<activation>

## When to Use

- After completing indicator, bot, or research workflows
- When reflecting on completed work to extract reusable knowledge
- When a build summary contains notable discoveries worth preserving

## Natural Language Triggers
- "what did we learn", "capture lessons", "retrospective", "lessons learned"

</activation>

## Overview

The lessons-learned system captures trading discoveries, strategy findings, and implementation pitfalls and feeds them into the project knowledge base. Lessons are stored in `.quantdev/LESSONS.md` for process insights and `.quantdev/KNOWLEDGE.md` for durable trading knowledge. Optionally surfaced in `CLAUDE.md` so future agents benefit from past experience.

<instructions>

## LESSONS.md Format

Store lessons in `.quantdev/LESSONS.md` using this exact structure:

```markdown
# Quantdev Lessons Learned

## [YYYY-MM-DD] Phase N: {Phase Name}

### What Went Well
- {Bullet point}

### Surprises / Discoveries
- {Pattern discovered}

### Pitfalls to Avoid
- {Anti-pattern encountered}

### Process Improvements
- {Workflow enhancement}

---
```

New entries are prepended after the `# Quantdev Lessons Learned` heading so the most recent phase appears first. Each phase gets its own dated section with all four subsections.

## Structured Prompts

Present these questions to the user during lesson capture:

1. **What went well?** -- Patterns, tools, or approaches that worked effectively.
2. **What surprised you or what did you learn?** -- Unexpected behaviors, market observations, revised assumptions.
3. **What should future work avoid?** -- Anti-patterns, dead ends, or approaches that caused problems.
4. **Any process improvements discovered?** -- Workflow changes, tooling suggestions, or efficiency gains.

### Trading-Specific Prompts

After backtests, optimizations, or strategy changes, also ask:

5. **Strategy findings** -- What did the backtest/optimization reveal about market behavior?
6. **Regime observations** -- Did performance vary by market regime? Which regimes worked/failed?
7. **Parameter sensitivity** -- Were there fragile parameters or robust plateaus?
8. **Cross-platform insights** -- Any differences between platform implementations?

## Pre-Population

Before presenting prompts, extract candidate lessons from:

1. `SUMMARY-*.md` files — issues encountered, decisions made
2. `JOURNAL.md` entries — strategy observations, parameter changes
3. Backtest result annotations — regime breakdowns, integrity flags
4. Optimization reports — sensitivity findings, walk-forward results

Present extracted items as pre-populated suggestions the user can accept, edit, or discard.

## Knowledge Base Integration

**LESSONS.md** captures process lessons (how we work):
```markdown
### Pitfalls to Avoid
- Pine Script ta.atr() uses Wilder's smoothing, not SMA — caused cross-platform drift
```

**KNOWLEDGE.md** captures durable trading knowledge (what we learned about markets):
```markdown
## ES Futures — Session Behavior
- Initial balance (09:30-10:30 ET) sets the day's range 68% of the time
- Overnight session moves >1% predict high-volatility RTH session
- CME maintenance window (16:00-17:00 CT) creates data gaps
```

Route each lesson to the appropriate file. Process insights → LESSONS.md. Market/strategy knowledge → KNOWLEDGE.md.

## CLAUDE.md Integration

After the user approves lessons, optionally append to `CLAUDE.md`:

1. If no `CLAUDE.md` exists, skip entirely.
2. Find or create a `## Lessons Learned` section.
3. Append concise single-line bullets (omit phase dates, focus on actionable guidance).

</instructions>

<rules>

## Quality Standards

Lessons must be **specific, actionable, and reusable**. Apply these filters:

**Anti-Patterns to reject:**
- Lessons that duplicate existing entries in LESSONS.md
- Lessons that reference specific line numbers or ephemeral file locations
- Lessons that are generic truisms rather than discovered knowledge
- Lessons longer than two sentences -- split or summarize

</rules>

<examples>

## Lesson Quality Examples

### Good Lesson -- specific, transferable, actionable

```
### Pitfalls to Avoid
- bats-core `run` captures exit code but swallows stderr -- use `2>&1` to capture both
```

Why it works: Names the exact tool and behavior, explains the symptom, and gives the fix.

### Good Lesson -- documents a non-obvious decision

```
### Surprises / Discoveries
- jq `.field // "default"` prevents null propagation in optional config values --
  without the fallback, downstream commands silently receive "null" as a string
```

### Bad Lesson -- vague platitude

```
### What Went Well
- Tests are important
```

Why it fails: Generic truism. Zero discovered knowledge.

### Bad Lesson -- too specific, not transferable

```
### Pitfalls to Avoid
- Fixed a bug on line 47 of parser.py
```

Why it fails: Line 47 will change. Future readers cannot act on this.

### Bad Lesson -- implementation detail, not a lesson

```
### Process Improvements
- Changed variable name from x to y
```

Why it fails: A code change, not a reusable insight.

</examples>

## Integration

**Referenced by:** Indicator, bot, and research workflows for post-work lesson capture.

**Pairs with:** `quantdev:quantdev-verification` for validating lesson quality before persisting.
