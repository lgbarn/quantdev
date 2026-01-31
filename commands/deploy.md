---
description: "Generate deployment configs for a trading bot (never executes live trades)"
disable-model-invocation: true
argument-hint: "<strategy-name> [--format docker|systemd|all]"
---

# /quantdev:deploy - Deployment Config Generation

You are executing the quantdev deployment config generation workflow. This generates Docker, systemd, and environment configurations for deploying a trading bot. **This command NEVER executes live trades — it only creates configuration files.** Follow these steps precisely.

<prerequisites>

## Step 1: Parse Arguments

Extract from the command:
- `strategy-name` (REQUIRED): The strategy to generate deployment configs for.
- `--format` (optional): Deployment format. Default: `all`. Valid: `docker`, `systemd`, `all`.

If no strategy name is provided, ask the user:
> "Which strategy needs deployment configs? Provide the strategy name."

## Step 2: Locate Strategy

1. Look for the strategy implementation in the codebase and `.quantdev/strategies/{strategy-name}/`.
2. If not found:
   > "Strategy '{strategy-name}' not found. Run `/quantdev:bot {strategy-name}` to build it first."
   Stop here.
3. Read the strategy's `PARAMS.json` and `HYPOTHESIS.md` for configuration context.

## Step 3: Detect Context

1. Read `.quantdev/config.json` for execution stack (Apex API, paper mode) and session config.
2. Follow **Worktree Protocol** (see `docs/PROTOCOLS.md`) — detect worktree context.

</prerequisites>

<execution>

## Step 4: Builder — Generate Configs

Dispatch a **Builder agent** (subagent_type: "quantdev:builder") with:
- Follow **Model Routing Protocol** — resolve model from `model_routing.building` (default: sonnet)
- max_turns: 20
- The strategy implementation and parameters
- Execution config from `.quantdev/config.json` (provider, API settings, paper mode)
- Session config (timezone, RTH hours)
- Instruction: Generate deployment configurations. **NEVER include actual API keys or secrets — use placeholder variables only.**

### Docker format (`--format docker` or `all`):

Generate:
- `deploy/{strategy-name}/Dockerfile` — Multi-stage build, non-root user, health check
- `deploy/{strategy-name}/docker-compose.yml` — Service definition with restart policy, logging, resource limits
- `deploy/{strategy-name}/.env.template` — Environment variable template with placeholders:
  ```
  # APEX API (NEVER commit real values)
  APEX_API_KEY=<your-api-key>
  APEX_API_SECRET=<your-api-secret>
  APEX_ACCOUNT_ID=<your-account-id>
  PAPER_MODE=true

  # Strategy parameters
  STRATEGY_NAME={strategy-name}
  # ... (from PARAMS.json)
  ```
- `deploy/{strategy-name}/.dockerignore`

### Systemd format (`--format systemd` or `all`):

Generate:
- `deploy/{strategy-name}/{strategy-name}.service` — Systemd unit file with:
  - `Restart=on-failure`, `RestartSec=5`
  - `EnvironmentFile` pointing to env file
  - `ExecStartPre` health check
  - Logging to journald
- `deploy/{strategy-name}/{strategy-name}.env` — Environment file template (same placeholders as Docker)

### Always generate:

- `deploy/{strategy-name}/README.md` — Deployment instructions:
  - How to configure credentials (copy `.env.template`, fill in values)
  - How to start in paper mode first
  - How to monitor logs
  - How to stop gracefully
  - **WARNING: Review all parameters and run backtests before going live**

## Step 5: Commit

Create atomic git commit:
```
feat({strategy-name}): add deployment configs ({format})
```

</execution>

<output>

## Step 6: Report

Display:
```
Deployment Configs: {strategy-name}
═══════════════════════════════════════════
Format: {docker|systemd|all}
Files created:
{list of files}

⚠ IMPORTANT:
  - Copy .env.template to .env and fill in your API credentials
  - NEVER commit .env files with real credentials
  - Start in PAPER_MODE=true first
  - Review all parameters before live trading
```

Suggest next steps:
> - Review the generated configs and fill in credentials
> - `/quantdev:backtest {strategy-name}` — Verify strategy performance before deploying
> - `/quantdev:risk {strategy-name}` — Confirm position sizing and risk limits

</output>
