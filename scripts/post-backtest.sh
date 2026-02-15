#!/usr/bin/env bash
# Post-backtest utility: auto-flags suspicious backtest results
# Called by the backtester agent or /quantdev:backtest command.
#
# Checks backtest results for overfitting signals and writes
# annotations to the strategy journal.
# Exit 0 = clean, Exit 2 = critical flags found.

set -euo pipefail

# Kill switch: skip all hooks
if [ "${QUANTDEV_DISABLE_HOOKS:-}" = "true" ]; then exit 0; fi
# Selective skip: comma-separated hook names
HOOK_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
if [[ ",${QUANTDEV_SKIP_HOOKS:-}," == *",$HOOK_NAME,"* ]]; then exit 0; fi

# Check for jq dependency
if ! command -v jq >/dev/null 2>&1; then
    echo "WARNING: jq not found, skipping backtest integrity check" >&2
    exit 0
fi

# Look for the most recent backtest result file
# Expected location: .quantdev/strategies/*/backtests/*.json
LATEST_RESULT=""
if [ -d ".quantdev/strategies" ]; then
    LATEST_RESULT=$(find .quantdev/strategies -name "*.json" -path "*/backtests/*" -type f 2>/dev/null | \
        sort -t/ -k1 | tail -1)
fi

# Also check for results passed via environment
if [ -n "${QUANTDEV_BACKTEST_RESULT:-}" ] && [ -f "${QUANTDEV_BACKTEST_RESULT}" ]; then
    LATEST_RESULT="${QUANTDEV_BACKTEST_RESULT}"
fi

if [ -z "$LATEST_RESULT" ]; then
    # No backtest results found — nothing to check
    exit 0
fi

# Extract metrics (gracefully handle missing fields)
SHARPE=$(jq -r '.sharpe // .sharpe_ratio // empty' "$LATEST_RESULT" 2>/dev/null || echo "")
WIN_RATE=$(jq -r '.win_rate // .win_pct // empty' "$LATEST_RESULT" 2>/dev/null || echo "")
PROFIT_FACTOR=$(jq -r '.profit_factor // .pf // empty' "$LATEST_RESULT" 2>/dev/null || echo "")
TRADE_COUNT=$(jq -r '.trade_count // .total_trades // .num_trades // empty' "$LATEST_RESULT" 2>/dev/null || echo "")
HAS_OOS=$(jq -r '.out_of_sample // .oos // .has_oos // empty' "$LATEST_RESULT" 2>/dev/null || echo "")
STRATEGY_NAME=$(jq -r '.strategy // .name // "unknown"' "$LATEST_RESULT" 2>/dev/null || echo "unknown")

FLAGS=""
SEVERITY="OK"

# Flag: Sharpe > 3.0 on daily data
if [ -n "$SHARPE" ]; then
    if awk "BEGIN{exit !($SHARPE > 3.0)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [CRITICAL] Sharpe ${SHARPE} > 3.0 — almost certainly overfitted"
        SEVERITY="CRITICAL"
    elif awk "BEGIN{exit !($SHARPE > 2.0)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [WARNING]  Sharpe ${SHARPE} > 2.0 — requires strong justification"
        [ "$SEVERITY" = "OK" ] && SEVERITY="WARNING"
    fi
fi

# Flag: Win rate > 75%
if [ -n "$WIN_RATE" ]; then
    if awk "BEGIN{exit !($WIN_RATE > 85)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [CRITICAL] Win rate ${WIN_RATE}% > 85% — almost certainly a bug or overfitting"
        SEVERITY="CRITICAL"
    elif awk "BEGIN{exit !($WIN_RATE > 75)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [WARNING]  Win rate ${WIN_RATE}% > 75% — check for lookahead or curve fitting"
        [ "$SEVERITY" = "OK" ] && SEVERITY="WARNING"
    fi
fi

# Flag: Profit factor > 4.0
if [ -n "$PROFIT_FACTOR" ]; then
    if awk "BEGIN{exit !($PROFIT_FACTOR > 6.0)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [CRITICAL] PF ${PROFIT_FACTOR} > 6.0 — almost certainly overfitted or buggy"
        SEVERITY="CRITICAL"
    elif awk "BEGIN{exit !($PROFIT_FACTOR > 4.0)}" 2>/dev/null; then
        FLAGS="${FLAGS}\n  [WARNING]  PF ${PROFIT_FACTOR} > 4.0 — unrealistic for sustained trading"
        [ "$SEVERITY" = "OK" ] && SEVERITY="WARNING"
    fi
fi

# Flag: < 30 trades
if [ -n "$TRADE_COUNT" ]; then
    if [ "$TRADE_COUNT" -lt 30 ] 2>/dev/null; then
        FLAGS="${FLAGS}\n  [CRITICAL] ${TRADE_COUNT} trades < 30 — statistically meaningless"
        SEVERITY="CRITICAL"
    elif [ "$TRADE_COUNT" -lt 100 ] 2>/dev/null; then
        FLAGS="${FLAGS}\n  [WARNING]  ${TRADE_COUNT} trades < 100 — low confidence in metrics"
        [ "$SEVERITY" = "OK" ] && SEVERITY="WARNING"
    fi
fi

# Flag: No out-of-sample testing
if [ -z "$HAS_OOS" ] || [ "$HAS_OOS" = "false" ] || [ "$HAS_OOS" = "null" ]; then
    FLAGS="${FLAGS}\n  [WARNING]  No out-of-sample period defined — cannot assess generalization"
    [ "$SEVERITY" = "OK" ] && SEVERITY="WARNING"
fi

# Output results
if [ -n "$FLAGS" ]; then
    echo ""
    echo "=== BACKTEST INTEGRITY CHECK: ${STRATEGY_NAME} ==="
    printf '%b\n' "$FLAGS"
    echo ""
    echo "Severity: ${SEVERITY}"

    if [ "$SEVERITY" = "CRITICAL" ]; then
        echo ""
        echo "CRITICAL flags detected. Review with quantdev:backtest-integrity skill before proceeding."
        echo "Run quantdev:lookahead-guard to check for data access bugs."
    fi

    # Write to strategy journal if it exists
    STRATEGY_DIR=$(dirname "$(dirname "$LATEST_RESULT")")
    JOURNAL="${STRATEGY_DIR}/JOURNAL.md"
    if [ -f "$JOURNAL" ]; then
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        {
            echo ""
            echo "## ${TIMESTAMP} — Backtest Integrity Check"
            printf '%b\n' "$FLAGS"
            echo "Severity: ${SEVERITY}"
        } >> "$JOURNAL"
    fi
fi

# Always allow (warnings only, never blocks)
exit 0
