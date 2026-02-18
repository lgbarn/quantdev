# Contributing to Quantdev

Thank you for your interest in contributing to Quantdev. This guide covers how to add commands, skills, and agents for trading development, run tests, and follow quantdev conventions.

## Prerequisites

See [README.md](README.md) for installation instructions.

System dependencies for development:

- **bash** >= 4.0
- **jq** >= 1.6
- **git** >= 2.20
- **node** >= 18 (for npm/bats test runner only)

## Adding Commands

Commands are slash commands exposed via `/quantdev:<name>`.

1. Create `commands/<name>.md` with required YAML frontmatter:

   ```yaml
   ---
   description: Short description of what the command does
   disable-model-invocation: true
   argument-hint: "[optional-arg] [--flag]"
   ---
   ```

2. Write the command body using a step-numbered workflow pattern (Step 1, Step 2, etc.).
3. Add the command to the Commands table in `README.md`.

## Adding Skills

Skills are auto-activating capabilities that trigger based on context.

1. Create a directory `skills/<name>/` using kebab-case naming.
2. Create `skills/<name>/SKILL.md` with this structure:

   ```markdown
   ---
   name: skill-name
   description: Use when [trigger context description]
   ---

   <!-- TOKEN BUDGET: N lines / ~M tokens -->

   # Skill Title

   ## Overview

   [What this skill does and when it activates.]

   ## Triggers

   [Conditions that activate this skill.]
   ```

3. Follow the consistent header block order: frontmatter, blank line, TOKEN BUDGET comment, blank line, `# Title`, blank line, Overview/Triggers.
4. Use kebab-case for the directory and skill name.
5. Skills are auto-discovered from `skills/*/SKILL.md` — no manual registration needed.
6. Add the skill to the Skills table in `README.md`.

## Adding Agents

Agents are specialized subagents dispatched by commands.

1. Create `.claude/agents/quantdev-<name>.md` with YAML frontmatter:

   ```yaml
   ---
   name: quantdev:<name>
   description: >
     Short description with examples of when this agent is used.
     Example: "Use this agent when implementing indicators or building bots."
   model: sonnet
   tools: Read, Edit, Write, Bash, Grep, Glob
   permissionMode: default
   maxTurns: 20
   ---
   ```

2. Valid `model` values: `opus`, `sonnet`, `haiku`, `inherit`.
3. Add the agent to the Agents table in `README.md`.
4. Follow the `quantdev:` prefix naming convention for all agents.

## Trading-Specific Conventions

### Naming Conventions
- All indicators and strategies use platform-specific naming conventions (no custom suffixes)
- Go: PascalCase types, snake_case files. Python: PEP 8 snake_case. Pine Script: camelCase vars, UPPER_CASE constants. NinjaScript: PascalCase matching filename. Tradovate: short descriptions.
- See the builder agent's Platform Naming Conventions table for the full reference

### Session Awareness
- All times in America/New_York (ET)
- RTH: 09:30-16:00, IB: 09:30-10:30, OVN: 18:00-09:30
- Session-dependent indicators (VWAP, volume profile) must reset at boundaries

### Platform Tiers
- **Tier 1 (Go, Python):** Source of truth for math. Backtest engine. Live bots.
- **Tier 2 (Pine Script):** Primary charting. Most indicators already exist here.
- **Tier 3 (NinjaScript C#, Tradovate JS):** Port when needed.

### Lookahead Prevention
- Never reference current bar's close in entry/exit decisions
- Use `[1]` indexing for confirmed bars
- All indicator calculations use only closed bar data

### Risk Parameters Required
- Every bot must have: max daily loss, per-trade risk, stop loss, position limits
- No unbounded positions allowed
- Apex margin requirements must be validated

## Running Tests

Quantdev uses [bats-core](https://github.com/bats-core/bats-core) for testing.

```bash
# Run all tests
npm test

# Or directly
bash test/run.sh
```

- Test files live in `test/` with the `.bats` extension.
- Shared helpers are in `test/test_helper.bash`.

## PR Requirements

Before submitting a pull request:

1. **All tests pass**: Run `npm test` and confirm zero failures.
2. **ShellCheck passes**: Run `shellcheck --severity=warning scripts/*.sh hooks/*.sh test/run.sh` with no errors.
3. **No duplicated content**: Ensure documentation is not repeated across files.
4. **Conventional commits**: Use the format `type(scope): description`. See `docs/PROTOCOLS.md` for the full commit convention.
5. **Platform naming conventions**: All new indicators and strategies must follow platform-specific naming standards (see builder agent).
6. **Session awareness validated**: Any time-dependent code must handle session boundaries correctly.

## Markdown Style Guide

| Element | Convention |
|---------|-----------|
| Document title | `#` (one per file) |
| Major sections | `##` |
| Subsections | `###` |
| Frontmatter | Required in commands, skills, and agents |
| File/directory names | kebab-case |
| Tables | Pipe-delimited |
| Code blocks | Triple-backtick with language hint |
| TOKEN BUDGET comments | Advisory, not enforced |

## Trading Development Guidelines

### Indicator Development
1. Design math with Strategy Architect
2. Implement in Go first (source of truth) in `pkg/indicators/`
3. Write golden-file tests
4. Port to other platforms as needed
5. Run `/quantdev:validate` to ensure cross-platform consistency

### Bot Development
1. Design entry/exit logic with Strategy Architect
2. Define risk parameters (max loss, stop loss, position limits)
3. Implement in Go (`pkg/engine/`, `pkg/signals/`) or Python (`lib/`, `bots/`)
4. Include session boundary handling
5. Never execute live trades — deployment configs only

### Research Workflow
1. Use Quant Researcher for statistical analysis
2. Document findings in `.quantdev/research/{topic}/FINDINGS.md`
3. Update knowledge base with market observations
4. Flag overfitting indicators: Sharpe > 3, win rate > 75%, < 30 trades

### Code Review Focus
1. **Stage 1 (trading correctness):** Lookahead bias, session boundaries, fill assumptions, risk parameters
2. **Stage 2 (code quality):** Platform conventions, pattern consistency, error handling

## Project Structure

```
.quantdev/
├── config.json          # platforms, data, execution, sessions
├── PROJECT.md           # trading system vision, goals
├── KNOWLEDGE.md         # market observations, strategy patterns, lessons
├── STATE.json           # current track, active strategy, status
├── strategies/
│   └── {name}/
│       ├── HYPOTHESIS.md    # strategy thesis, entry/exit rules
│       ├── PARAMS.json      # current parameters
│       ├── JOURNAL.md       # observations, changes, lessons
│       ├── backtests/       # timestamped results
│       └── optimization/    # parameter sweep results
├── research/
│   └── {topic}/
│       └── FINDINGS.md
└── validation/
    └── golden/          # cross-platform reference data
```

## Common Agent Patterns

When adding new agents, follow these patterns:

- **Read-only analysis agents:** Researcher, Risk Analyst, Debugger, Documenter
- **Implementation agents:** Builder (full tool access)
- **Validation agents:** Reviewer, Strategy Verifier, Cross-Platform Validator (read + bash for tests)
- **Orchestration agents:** Backtester, Optimizer (read + bash for runs + write for results)

## Questions?

Open an issue or see the design doc: `docs/plans/2026-02-14-quantdev-transformation-design.md`
