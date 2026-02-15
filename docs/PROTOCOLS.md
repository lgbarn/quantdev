# Quantdev Protocols

Shared protocols referenced by commands and agents. Each protocol is self-contained — copy the relevant section into agent prompts as needed.

---

## State Loading Protocol

<purpose>
Load project state files to establish context for the current session. This is the first step in every command that needs to understand where the project is.
</purpose>

<instructions>
Read the following files (skip any that don't exist):

1. `.quantdev/STATE.json` — current track (indicator/bot/research), active strategy, status
2. `.quantdev/PROJECT.md` — trading system vision, goals, asset focus
3. `.quantdev/KNOWLEDGE.md` — accumulated market/strategy knowledge base
4. `.quantdev/config.json` — platforms, data paths, execution stack, model routing
5. Recent strategy journals from `.quantdev/strategies/{name}/JOURNAL.md` — strategy evolution and observations
6. Recent backtest results from `.quantdev/strategies/{name}/backtests/` — performance metrics
7. Recent research findings from `.quantdev/research/{topic}/FINDINGS.md` — quantitative insights

Use STATE.json to determine the current track and active work. Use PROJECT.md for trading system vision and goals. Use KNOWLEDGE.md for accumulated market knowledge.

**State structure:** `.quantdev/STATE.json` tracks active strategies, recent backtests, pending validations, and knowledge base stats.
</instructions>

<rules>
- Never fail if a file is missing — skip it and proceed with available context
- STATE.json is the single source of truth for current work
- Knowledge base is living documentation — always read latest before starting new work
- Strategy journals capture evolution over time — read for context on existing strategies
- Backtest results include overfitting flags — check before drawing conclusions
</rules>

<example description="Correct state loading for strategy work">
1. Read STATE.json → `jq -r '.active_track' .quantdev/STATE.json` → "bot"
2. Read STATE.json → `jq -r '.current_strategy' .quantdev/STATE.json` → "KeltnerLB"
3. Read .quantdev/strategies/KeltnerLB/HYPOTHESIS.md → Strategy thesis and parameters
4. Read .quantdev/strategies/KeltnerLB/JOURNAL.md → Recent observations and changes
5. Read .quantdev/KNOWLEDGE.md → Market observations relevant to Keltner strategies
6. Conclusion: Resume bot development for KeltnerLB strategy
</example>

---

## Model Routing Protocol

<purpose>
Select the correct model for each agent dispatch. Respects user-configured overrides in config.json while providing sensible defaults. This ensures expensive models are used only where they add value.
</purpose>

<instructions>
Read `model_routing` from `.quantdev/config.json` and map agent roles to model keys:

| Agent Role | Config Key | Default |
|---|---|---|
| Strategy Architect | `model_routing.architecture` | opus |
| Quant Researcher | `model_routing.planning` | opus |
| Risk Analyst | `model_routing.security_audit` | opus |
| Builder | `model_routing.building` | sonnet |
| Reviewer | `model_routing.review` | sonnet |
| Strategy Verifier | `model_routing.validation` | sonnet |
| Optimizer | `model_routing.simplification` | sonnet |
| Backtester | `model_routing.debugging` | sonnet |
| Debugger | `model_routing.debugging` | sonnet |
| Documenter | `model_routing.documentation` | sonnet |
| Cross-Platform Validator | `model_routing.mapping` | haiku |

The `debugging` config key maps to the debugger agent (subagent_type: `quantdev:debugger`), dispatched by `/quantdev:debug` for root-cause analysis.

The `security_audit` config key maps to the Risk Analyst agent (subagent_type: `quantdev:risk-analyst`), dispatched by `/quantdev:risk` for position sizing and drawdown analysis.

Pass the resolved model name as the `model` parameter in the Task tool call. Model names (`opus`, `sonnet`, `haiku`) resolve to the latest available version at dispatch time. Currently: Opus 4.6, Sonnet 4.5, Haiku 4.5.
</instructions>

<rules>
- If `model_routing` is absent from config.json, use the defaults from the table above
- Never hardcode a model — always check config first
- The user may override any role; respect their choice even if it seems suboptimal
</rules>

<example description="Correct model resolution">
config.json contains: `"model_routing": { "building": "opus", "review": "haiku" }`

Dispatching a Builder → use "opus" (user override)
Dispatching a Reviewer → use "haiku" (user override)
Dispatching a Verifier → use "haiku" (default — no override specified)
Dispatching an Architect → use "opus" (default — no override specified)
Dispatching a Simplifier → use "sonnet" (default — no override for `simplification`)
</example>

### Model Selection Guidance

When customizing model routing, consider these tradeoffs:

| Config Key | Upgrade to Opus When... | Downgrade to Sonnet When... |
|---|---|---|
| `architecture` | (Always Opus) Novel strategy design, regime-aware logic | N/A — always use Opus |
| `planning` | (Always Opus) Statistical analysis, academic review | N/A — always use Opus |
| `security_audit` | **Complex risk modeling, portfolio optimization, Kelly criterion** | Simple position sizing checks |
| `building` | Complex algorithmic indicators; novel signal logic | Standard implementations; boilerplate |
| `review` | Multi-platform trading correctness; complex bot logic | Simple indicator ports; formatting |
| `validation` | Complex multi-stage empirical verification | Code-level checklist only (Stage 1) |
| `simplification` | Deep parameter sensitivity analysis | Standard grid search |
| `debugging` | **Complex multi-platform bugs; cross-system discrepancies** | Simple test failures; obvious errors |
| `documentation` | Strategy journals with quantitative analysis | Simple parameter updates |
| `mapping` | (Always Haiku) Fast golden-file comparison | N/A — always use Haiku |

### Context Tier Model Adjustment

When `context_tier` is `"auto"` in config.json, commands should assess the scope of changes before dispatching agents and adjust the model selection accordingly. This applies **after** reading `model_routing` config — user overrides always win.

| Condition | Tier | Model Adjustment |
|---|---|---|
| <5 files changed, single plan | light | Use default or downgrade one step (sonnet→haiku) |
| 5-20 files, single phase | standard | Use default model for the role |
| >20 files, security-sensitive, or cross-phase | heavy | Upgrade one step (haiku→sonnet, sonnet→opus) |

**How to assess tier:**
1. Count files in the git diff or plan's file list
2. Check if the phase involves security, authentication, or PII handling
3. Check if the work spans multiple phases or cross-cutting concerns

**Model step ladder:** haiku → sonnet → opus. Downgrade means move left; upgrade means move right. Never downgrade below haiku or upgrade above opus.

**Example:**
- Verifier (default: haiku) checking a 25-file phase with auth changes → tier: heavy → upgrade to sonnet
- Reviewer (default: sonnet) checking a 2-file formatting change → tier: light → downgrade to haiku
- Builder (default: sonnet) implementing a 10-file feature → tier: standard → keep sonnet

**Full config.json structure** (used during `/quantdev:init`):
```json
{
  "platforms": {
    "tier1": ["go", "python"],
    "tier2": ["pinescript"],
    "tier3": ["ninjatrader", "tradovate"]
  },
  "data": {
    "historical_path": "data/GLBX",
    "formats": ["csv", "parquet"],
    "source": "databento_manual_download"
  },
  "execution": {
    "provider": "apex",
    "api": "direct",
    "paper_mode": true
  },
  "live_data": {
    "provider": "topstepx"
  },
  "sessions": {
    "timezone": "America/New_York",
    "rth": ["09:30", "16:00"],
    "initial_balance": ["09:30", "10:30"],
    "overnight": ["18:00", "09:30"]
  },
  "model_routing": {
    "architecture": "opus",
    "planning": "opus",
    "security_audit": "opus",
    "building": "sonnet",
    "review": "sonnet",
    "validation": "sonnet",
    "simplification": "sonnet",
    "debugging": "sonnet",
    "documentation": "sonnet",
    "mapping": "haiku"
  },
  "knowledge_base": true,
  "created_at": "<timestamp>",
  "version": "1.0"
}
```

**Defaults:** Platform tiers as shown, data path `data/GLBX/`, Apex execution, TopStepX live data, ET session times, knowledge base enabled.

**Config version:** The `version` field tracks the config schema version (currently `"1.0"` for quantdev). This is set by `/quantdev:init` and used internally to detect when config format changes require migration. Users should not modify this field.

---

## Checkpoint Protocol

<purpose>
Create named git tag checkpoints at key pipeline stages so the user can roll back if a subsequent step fails. Checkpoints are lightweight — they add no overhead but provide critical safety nets.
</purpose>

<instructions>
Run the checkpoint script with a descriptive label:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/checkpoint.sh "<label>"
```

Create checkpoints at the pipeline stages specified by the command workflow.
</instructions>

<rules>
- Labels must be alphanumeric with hyphens only (no spaces, no special characters)
- Always create the checkpoint before the risky operation, not after
- Each checkpoint creates a lightweight git tag — it does not create a commit
</rules>

**Standard checkpoint names:**
- `pre-build-phase-{N}` — before build execution starts
- `post-plan-phase-{N}` — after planning completes
- `post-build-phase-{N}` — after build and verification complete

<example description="Checkpoint placement in build pipeline">
1. Planning completes → checkpoint "post-plan-phase-3"
2. About to start building → checkpoint "pre-build-phase-3"
3. Builder runs, reviewer approves, verifier passes
4. All gates pass → checkpoint "post-build-phase-3"
5. If step 3 fails → user can rollback to "pre-build-phase-3"
</example>

---

## Worktree Protocol

<purpose>
Detect and record the git worktree context so agents operate on the correct paths and branch. Without this, agents may modify files in the wrong working tree or commit to the wrong branch.
</purpose>

<instructions>
1. Run `git worktree list` to identify if operating in a worktree
2. Record `$(pwd)` as the working directory
3. Record `$(git branch --show-current)` as the current branch
4. Pass working directory, current branch, and worktree status to all dispatched agents
</instructions>

<rules>
- **In a worktree:** All file operations are relative to the worktree directory. Git operations (commit, diff, status) operate on the worktree's branch. The `.quantdev/` directory lives in the main working tree — reference it via the path from `git worktree list`.
- **In the main working tree:** Assume standard paths relative to the project root.
- Always pass these three values to every agent dispatch: working directory, branch name, worktree boolean.
</rules>

<example description="Worktree detection and agent dispatch">
`git worktree list` output:
```
/home/user/myproject          abc1234 [main]
/home/user/myproject-phase-3  def5678 [phase-3-auth]
```

Current directory is `/home/user/myproject-phase-3` → operating in worktree.
- Working directory: `/home/user/myproject-phase-3`
- Branch: `phase-3-auth`
- .quantdev/ path: `/home/user/myproject/.quantdev/`
- Pass all three to agent prompts
</example>

---

## Issue Tracking Protocol

<purpose>
Persist non-blocking findings in `.quantdev/ISSUES.md` so they survive across sessions and accumulate for later resolution. Without this, reviewer and auditor suggestions are lost when the session ends.
</purpose>

<instructions>
When non-blocking issues are found (Important or Suggestion severity):

1. Check if `.quantdev/ISSUES.md` exists; if not, create it with the table header
2. Append findings as new rows to the Open Issues table
3. Auto-increment the ID from the highest existing ID
4. Set `source` to the agent role (e.g., "reviewer", "auditor", "simplifier")
5. Map severity: Important → medium, Suggestion → low
6. Set date to current date (YYYY-MM-DD)
</instructions>

<rules>
- Never overwrite existing issues — only append new rows
- Critical findings are NOT issues — they block the pipeline and must be resolved immediately
- Do not duplicate: check if a similar issue already exists before appending
- Issues are resolved via `/quantdev:issues` which marks them as closed
</rules>

<example description="Appending a reviewer finding to ISSUES.md">
Reviewer finds: "The `processPayment` function has no input validation but is not blocking."

Append to ISSUES.md:
```markdown
| 7 | reviewer | medium | 2026-02-04 | `processPayment` in `src/payments.ts` lacks input validation for amount parameter |
```
</example>

---

## Codebase Docs Protocol

<purpose>
Load project-specific documentation (conventions, architecture, stack) so agents understand the codebase context. This replaces generic assumptions with project-specific knowledge.
</purpose>

<instructions>
1. Read `codebase_docs_path` from `.quantdev/config.json`
   - If not specified, use default: `.quantdev/codebase`
2. Load files from that path (skip any that don't exist):
   - `CONVENTIONS.md` — Code style and project conventions
   - `STACK.md` — Technology stack and versions
   - `ARCHITECTURE.md` — System architecture and design patterns
   - `CONCERNS.md` — Known technical concerns and tech debt
   - `TESTING.md` — Test framework, patterns, and coverage expectations
   - `INTEGRATIONS.md` — External services and APIs
   - `STRUCTURE.md` — Directory layout with annotations
3. Pass loaded content to agents as context alongside the agent prompt
</instructions>

<rules>
- The path is either `.quantdev/codebase/` (private, gitignored) or `docs/codebase/` (committed to git), based on user choice at init time
- Never fail if the directory or any file is missing — these are optional
- Pass only the files that exist; do not generate placeholders
- CONVENTIONS.md is the highest-priority file — if only one file exists, pass that one
</rules>

---

## Agent Context Protocol

<purpose>
Define the standard context bundle to pass when dispatching any agent via the Task tool. Ensures agents have the information they need without overloading them with irrelevant content.
</purpose>

<instructions>
**Essential context (pass to every agent):**
- `.quantdev/PROJECT.md` — Project overview and requirements
- `.quantdev/config.json` — Workflow preferences and model routing
- Working directory path (`$(pwd)`)
- Current git branch (`$(git branch --show-current)`)
- Worktree status (via Worktree Protocol above)

**Conditional context (pass if exists and is relevant to the agent's task):**
- `.quantdev/STATE.json` — Current state (machine state)
- `.quantdev/HISTORY.md` — Audit trail for execution tier agents
- Codebase docs (via Codebase Docs Protocol above)
- Previous phase/plan results (`SUMMARY.md`, `RESEARCH.md` files)
- `.quantdev/ISSUES.md` — Open issues
- `.quantdev/phases/{N}/CONTEXT-{N}.md` — User decisions from Discussion Capture

**Agent-specific additions:**
- **Builder:** CONVENTIONS.md, results from previous waves in the same phase, CONTEXT file
- **Reviewer:** Git diff of changed files, the plan being reviewed, CONTEXT file
- **Auditor:** All changed files across the phase, dependency manifests (package.json, Cargo.toml, go.mod, etc.)
- **Documenter:** Existing docs in `docs/`, all SUMMARY.md files from the milestone
- **Simplifier:** All changed files across the phase, original plan scope for comparison
</instructions>

<rules>
- Never pass the entire `.quantdev/` directory — select only relevant files
- Essential context is mandatory; skipping it causes agents to make incorrect assumptions
- For multi-wave builds, pass SUMMARY.md from completed waves so later builders know what was already done
- Context file paths must be absolute or relative to the working directory — never use `~` or environment variables in agent prompts
</rules>

<example description="Context bundle for a Builder agent">
Good — focused context:
```
Project: .quantdev/PROJECT.md (requirements)
Config: .quantdev/config.json (git_strategy, model_routing)
Conventions: .quantdev/codebase/CONVENTIONS.md (code style)
Plan: .quantdev/phases/3/wave-2/plan-1/PLAN.md (what to build)
Prior work: .quantdev/phases/3/wave-1/plan-1/SUMMARY.md (wave 1 results)
Decisions: .quantdev/phases/3/CONTEXT-3.md (user preferences)
Branch: feature/phase-3-auth
Working dir: /home/user/myproject
```

Bad — context overload:
```
Passing all 7 codebase docs + all phase summaries from phases 1-6 + full ROADMAP.md + full ISSUES.md
```
Agents perform better with focused, relevant context than with everything available.
</example>

### Turn Limits

Pass `max_turns` when dispatching agents via the Task tool to prevent runaway execution. These are recommended values based on each agent's typical scope:

| Agent | Recommended max_turns | Rationale |
|---|---|---|
| Builder | 30 | Executes up to 3 tasks with TDD cycles; each task may need ~10 turns |
| Reviewer | 15 | Reviews a single plan's diff; scope is bounded |
| Verifier | 15 | Runs verification commands and checks criteria |
| Auditor | 15 | Analyzes phase diff against security checklist |
| Simplifier | 10 | Read-only analysis of phase changes |
| Documenter | 20 | May generate multiple documentation files |
| Researcher | 15 | Web search + codebase analysis |
| Architect | 15 | Plan decomposition bounded by 3-task-max rule |
| Mapper | 20 | Deep codebase analysis of one focus area |

Commands that dispatch agents should include the `max_turns` parameter in the Task tool call alongside `subagent_type` and `model`.

---

## State Update Protocol

<purpose>
Keep `.quantdev/STATE.json` current after every workflow step. STATE.json is the single source of truth for project progress — stale state causes incorrect resume behavior and confuses subsequent commands.
</purpose>

<instructions>
After each workflow step, update STATE.json via the state-write.sh script:

```bash
bash scripts/state-write.sh --phase {N} --position "{description}" --status {status}
```

**Required fields:**
- `phase` — Phase number (integer)
- `position` — Human-readable description of where work stands
- `status` — One of the canonical status values below

**History handling:**
History entries are automatically appended to `.quantdev/HISTORY.md` by state-write.sh based on the phase, position, and status values. Do not manually edit HISTORY.md.
</instructions>

**Canonical status values:**
| Status | Meaning |
|---|---|
| `ready` | Initialized, ready to start work |
| `designing` | Strategy Architect designing strategy/indicator |
| `building` | Builder implementing code |
| `backtesting` | Backtester running engine |
| `optimizing` | Optimizer running parameter sweeps |
| `researching` | Quant Researcher conducting analysis |
| `validating` | Cross-Platform Validator comparing implementations |
| `deploying` | Generating deployment configs |
| `complete` | Work completed |

<rules>
- Always commit STATE.json updates along with related artifacts in the same commit
- Position should be specific enough to enable resume (e.g., "KeltnerLB building, tests passing" not just "building")
- Status transitions follow work type: ready → designing/building/backtesting/optimizing/researching/validating/deploying → complete
- Always use state-write.sh to update state — do not manually edit STATE.json
</rules>

<example description="State update after completing indicator design">
Before STATE.json:
```json
{
  "last_updated": "2026-02-14",
  "active_track": "indicator",
  "current_strategy": "KeltnerLB",
  "status": "ready"
}
```

After running:
```bash
bash scripts/state-write.sh --track indicator --strategy KeltnerLB --status designing
```

STATE.json now contains:
```json
{
  "last_updated": "2026-02-14",
  "active_track": "indicator",
  "current_strategy": "KeltnerLB",
  "status": "designing"
}
```
</example>

---

## Native Task Scaffolding Protocol

<purpose>
Map Quantdev workflow stages to native Claude Code tasks (TaskCreate/TaskUpdate) so the user sees real-time progress tracking in their terminal. This provides visibility without requiring users to check STATE.json manually.
</purpose>

<instructions>
**At init time (per phase):**
- Create one task per phase: "Phase {N}: {phase_title}"
- All start as `pending` except Phase 1 (set to `in_progress`)

**At planning time (per phase):**
- Create one task per plan: "Phase {N} / Plan {W}.{P}: {plan_title}"
- Set status: `pending`
- Set `blockedBy` for plans that depend on earlier waves completing

**At build time (per plan):**
- Mark the plan's task as `in_progress` when the builder starts
- When builder completes, check SUMMARY.md status:
  - `complete` → mark task as `completed`
  - `partial` or `failed` → keep task as `in_progress`
- When review has `CRITICAL_ISSUES` after max retries → keep task as `in_progress` and create a new blocking task describing the issue

**At resume time:**
- Call TaskList to check for existing tasks
- If missing or stale, recreate from ROADMAP.md and artifact existence
- Set status based on whether SUMMARY.md exists and its content
</instructions>

<rules>
- Task subjects should be concise and follow the naming patterns above
- Always provide `activeForm` (present continuous) when creating tasks: "Building Phase 3 / Plan 2.1"
- Do not create tasks for internal steps (checkpoints, state updates) — only for user-visible milestones
- When a phase completes, mark its parent task as `completed` as well
</rules>

<example description="Task scaffolding for a 2-wave phase">
After planning Phase 3 (2 waves, 3 plans):

Task 1: "Phase 3 / Plan 1.1: Auth middleware" — pending
Task 2: "Phase 3 / Plan 1.2: Token refresh" — pending
Task 3: "Phase 3 / Plan 2.1: Integration tests" — pending, blockedBy: [1, 2]

After wave 1 completes:
Task 1: completed
Task 2: completed
Task 3: in_progress (automatically unblocked)
</example>

---

## Discussion Capture Protocol

<purpose>
Capture user decisions and preferences for a phase before planning begins. This prevents architects and builders from making assumptions about ambiguous requirements, and ensures the user's intent is preserved across sessions.
</purpose>

<instructions>
1. Read the target phase description from ROADMAP.md
2. Present the phase scope to the user in a concise summary
3. Identify gray areas: ambiguous requirements, multiple valid approaches, design choices with tradeoffs
4. Ask targeted questions one at a time (use AskUserQuestion with multiple-choice options preferred)
5. Write all decisions to `.quantdev/phases/{N}/CONTEXT-{N}.md`
</instructions>

**CONTEXT file format:**
```markdown
# Phase {N} Context: {phase title}

**Captured:** {YYYY-MM-DD}

## Decisions

### {Topic 1}
**Question:** {What was asked}
**Decision:** {What the user chose}
**Rationale:** {Why, if provided}

### {Topic 2}
...
```

<rules>
- Skip discussion capture if:
  - User passes `--no-discuss`
  - `CONTEXT-{N}.md` already exists (ask user if they want to redo it)
- Questions should be specific and actionable — not "what do you want?" but "Should auth use JWT or session cookies?"
- Limit to 3-5 questions per phase; prioritize decisions that affect architecture
- All downstream agents (researcher, architect, builder, reviewer) must receive CONTEXT-{N}.md as input context when it exists
</rules>

<example description="Good vs bad discussion questions">
Good questions (specific, actionable, affect architecture):
- "Should the API use REST or GraphQL for the new endpoints?"
- "Should auth tokens be stored in httpOnly cookies or localStorage?"
- "Should we add database migrations or recreate the schema?"

Bad questions (vague, no architectural impact):
- "What do you think about the phase scope?"
- "Any preferences for how we should proceed?"
- "Do you want me to use best practices?"
</example>

---

## Commit Convention

<purpose>
Standardize commit messages across all Quantdev work for consistent history and changelog generation. Conventional commits enable automated tooling and make git history scannable.
</purpose>

<instructions>
Use conventional commit format: `type(scope): description`

**Standard prefixes:**
| Prefix | Usage |
|---|---|
| `feat(scope)` | New indicator, bot, or feature |
| `fix(scope)` | Bug fix (trading bugs, session issues, lookahead bias) |
| `refactor(scope)` | Code change that neither fixes a bug nor adds a feature |
| `test(scope)` | Adding or updating tests (golden-file, behavioral, regression) |
| `docs(scope)` | Documentation changes (strategy journals, knowledge base) |
| `chore(scope)` | Maintenance tasks (deps, config) |

**Trading-specific scopes:**
| Scope | Usage |
|-------|-------|
| `(keltner)` | KeltnerLB indicator or strategy |
| `(vwap)` | VWAPLB indicator or strategy |
| `(supertrend)` | SupertrendLB indicator or strategy |
| `(ema)` | EMALB indicator or strategy |
| `(backtest)` | Backtest engine or results |
| `(optimize)` | Optimization tooling |
| `(risk)` | Risk analysis or position sizing |
</instructions>

<rules>
- Scope should match the indicator, bot, or component affected (e.g., `keltner`, `vwap`, `backtest`)
- Description should be imperative mood, lowercase, no period: "add ATR filter" not "Added ATR filter."
- Keep the first line under 72 characters
- Use LB suffix in scope when referring to specific strategies: `feat(keltner): add ATR period sensitivity filter`
</rules>

<example description="Good vs bad commit messages">
Good:
- `feat(keltner): add ATR period sensitivity filter`
- `fix(vwap): reset cumulative volume at session boundary`
- `test(supertrend): add golden-file comparison for ATR calculation`
- `refactor(signals): extract common filter interface`
- `docs(knowledge): add regime detection findings for mean reversion`

Bad:
- `updated indicator` (no type, no scope, vague)
- `feat: Changes` (vague description, capitalized)
- `fix(vwap): Fixed the bug where VWAP was carrying over across sessions and causing incorrect signals during the overnight session` (too long)
</example>

---

## Team Dispatch Protocol

<purpose>
Standardize the detect/ask/branch pattern used by multi-agent commands (build, plan, map, ship) to optionally use Claude Code native teams instead of Task subagents. This ensures consistent behavior, language, and cleanup patterns across all team-capable commands.
</purpose>

<instructions>
1. **Detect:** Check `QUANTDEV_TEAMS_ENABLED` environment variable (exported by `scripts/team-detect.sh`). Set to `true` when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

2. **Prompt (conditional):** If `QUANTDEV_TEAMS_ENABLED=true`, use `AskUserQuestion` with exactly two options:
   - "Team mode (parallel teammates)" — uses TeamCreate/TaskCreate/SendMessage/TeamDelete lifecycle
   - "Agent mode (subagents)" — uses standard Task dispatch (current behavior)
   - Question text: "Teams available. Use team mode (parallel teammates) or agent mode (subagents)?"

3. **Silent fallback:** If `QUANTDEV_TEAMS_ENABLED` is `false` or unset, silently set `dispatch_mode` to `agent` with no prompt (zero overhead).

4. **Variable storage:** Store the result as `dispatch_mode` (value: `team` or `agent`). This variable is referenced by all subsequent dispatch steps in the command.

5. **Team mode lifecycle:**
   - `TeamCreate(name: "quantdev-{command}-{scope}")` — descriptive team name
   - `TaskCreate` for each unit of work with full context
   - `TaskUpdate` to pre-assign owners BEFORE spawning teammates (avoids race conditions)
   - `Task(team_name, name, subagent_type)` to spawn each teammate
   - `TaskList` to monitor progress (poll until terminal state)
   - `SendMessage(shutdown_request)` to all teammates when done
   - `TeamDelete` for cleanup

6. **Agent mode:** Standard `Task(subagent_type, model, prompt)` dispatch. No TeamCreate/SendMessage/TeamDelete overhead.

7. **Single-agent exception:** Steps that dispatch only one agent (verifier, auditor, simplifier, documenter, researcher, architect) always use Task dispatch regardless of `dispatch_mode`. Team overhead is not justified for a single agent.

8. **Team cleanup is mandatory:** Always run `SendMessage(shutdown_request)` + `TeamDelete` even if errors occur. Before any early return or error exit in team mode, ensure team cleanup runs. Never leave orphaned teams.
</instructions>

<rules>
- The dispatch section must appear in `<prerequisites>` before any agent dispatch steps
- All 4 commands (build, plan, map, ship) must use identical detection, prompt, and fallback language
- Sequential-workflow commands (plan, ship) should include a recommendation note that agent mode is preferred
- Pre-assignment via TaskUpdate before spawning prevents race conditions — there is no atomic claiming
- Team names should be descriptive and scoped: `quantdev-build-phase-{N}-wave-{W}`, `quantdev-map-all`
</rules>

<example description="Dispatch pattern in a command with both parallel and single-agent steps">
Build command (parallel builders, single-agent reviewers):

1. Step 2b: Team or Agent Dispatch — detect, prompt, store dispatch_mode
2. Step 4a (Builders): if team → TeamCreate + TaskCreate + spawn; if agent → parallel Task calls
3. Step 4c (Reviewers): if team → same team or new team + TaskCreate + spawn; if agent → parallel Task calls
4. Step 5 (Verifier): always Task dispatch (single agent)
5. Steps 5a/5b/5c (Audit, Simplify, Document): always Task dispatch (single agent)
6. Team Cleanup: shutdown + delete after each team-mode section
</example>
