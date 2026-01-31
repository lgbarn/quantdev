# Quantdev Quickstart

Quantdev is a Claude Code plugin for structured project execution. It helps you plan, build, review, and ship software systematically — with parallel agents, TDD, security audits, and quality gates. If you're new to Quantdev, start here.

## I Want To...

### Start a New Project or Feature
| Situation | Command |
|-----------|---------|
| Set up a new project | `/quantdev:init` |
| Explore requirements interactively | `/quantdev:brainstorm` |
| Plan a phase of work | `/quantdev:plan 1` |
| Build from a plan | `/quantdev:build` (execute plans with builder agents, review gates, and security audits) |
| Quick single task | `/quantdev:quick "add health check endpoint"` |
| Ship completed work | `/quantdev:ship` (verify and deliver — merge, PR, or preserve) |

### Review and Improve Code
| Situation | Command |
|-----------|---------|
| Review uncommitted changes | `/quantdev:review` |
| Review a branch | `/quantdev:review main..HEAD` |
| Review specific files | `/quantdev:review src/auth/` |
| Security audit on changes | `/quantdev:audit` |
| Security audit on codebase | `/quantdev:audit .` |
| Find duplication/complexity | `/quantdev:simplify src/` |

### Research and Understand
| Situation | Command |
|-----------|---------|
| Evaluate technology options | `/quantdev:research "Redis vs Memcached for caching"` |
| Understand a codebase | `/quantdev:map` |
| Map architecture patterns | `/quantdev:map architecture` |
| Find technical debt | `/quantdev:map concerns` |

### Document and Verify
| Situation | Command |
|-----------|---------|
| Generate docs for changes | `/quantdev:document` |
| Document a module | `/quantdev:document src/api/` |
| Run tests and check criteria | `/quantdev:verify` |
| Verify phase completion | `/quantdev:verify 3` |

### Manage State
| Situation | Command |
|-----------|---------|
| Check progress | `/quantdev:status` |
| Resume previous session | `/quantdev:resume` |
| View or change settings | `/quantdev:settings` |
| Set a single setting | `/quantdev:settings security_audit false` |
| Rollback to checkpoint | `/quantdev:rollback` |
| Recover from errors | `/quantdev:recover` |
| View deferred issues | `/quantdev:issues` |
| View past phase history | Read `.quantdev/HISTORY.md` or `/quantdev:status` |
| Isolate feature work | `/quantdev:worktree create feature-name` |
| Move codebase docs location | `/quantdev:move-docs` |

## Lifecycle vs On-Demand

**Lifecycle commands** (`init` → `brainstorm` → `plan` → `build` → `ship`) run the full pipeline with multiple agents, review gates, security audits, and state tracking. Use these for structured multi-phase work.

**On-demand commands** (`review`, `audit`, `simplify`, `document`, `research`, `verify`, `map`) dispatch a single agent for a focused task. Use these for quick analysis without the full pipeline.

| When to use... | Lifecycle | On-Demand |
|----------------|-----------|-----------|
| Multi-phase feature | Yes | |
| Quick code review | | Yes |
| Pre-commit security check | | Yes |
| New project setup | Yes | |
| Technology investigation | | Yes |
| Full build + review + audit | Yes | |
| Spot-check code quality | | Yes |

## Model Routing

Quantdev routes each agent to an appropriate model tier:

| Tier | Agents | Cost | Best For |
|------|--------|------|----------|
| **Opus** | architect | Highest | Complex decomposition, architecture decisions |
| **Sonnet** | builder, reviewer, auditor, simplifier, documenter, researcher, mapper | Medium | Implementation, review, analysis |
| **Haiku** | verifier | Lowest | Validation, mechanical checks |

**Override defaults** in `.quantdev/config.json`:
```json
{
  "model_routing": {
    "security_audit": "opus",
    "building": "haiku",
    "review": "haiku"
  }
}
```

Upgrade `security_audit` to opus for production systems with PII or financial data. Downgrade `building` and `review` to haiku for simple formatting or config tasks.

## Common Workflows

### New Project
```
/quantdev:init          → configure project preferences
/quantdev:brainstorm    → explore requirements, capture project definition
/quantdev:plan 1        → decompose phase 1 into tasks
/quantdev:build         → execute with agents + review gates
/quantdev:ship          → verify, audit, document, deliver
```

### Adding a Feature
```
/quantdev:research "best approach for X"    → explore options
/quantdev:quick "add feature X"             → plan + build in one step
/quantdev:review                            → review before pushing
```

### Fixing a Bug
```
/quantdev:quick "fix auth token expiry bug" → diagnose + fix + test
/quantdev:verify                            → confirm fix works
```

### Pre-Ship Review
```
/quantdev:review main..HEAD    → review all branch changes
/quantdev:audit main..HEAD     → security audit
/quantdev:simplify main..HEAD  → check for bloat
/quantdev:document             → update docs
```

### Understanding Legacy Code
```
/quantdev:map                  → technology stack
/quantdev:map architecture     → architecture patterns
/quantdev:map quality          → code quality and conventions
/quantdev:map concerns         → technical debt and risks
```

## Tips

- **Agents start fresh every time** — they have no memory of previous dispatches. Context is passed explicitly.
- **`/quantdev:quick` is underrated** — use it for small tasks instead of manual coding. You still get TDD, review, and atomic commits.
- **Review before audit** — fix functional bugs before running security analysis.
- **Most on-demand commands work without `/quantdev:init`** — review, audit, simplify, research, and map can run on any git repo. Phase-specific commands like `verify 3` require `.quantdev/` state.
- **`/quantdev:settings` for quick adjustments** — toggle security audit, change model routing, or adjust context tier without re-initializing.
