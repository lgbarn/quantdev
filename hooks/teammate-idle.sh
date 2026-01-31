#!/usr/bin/env bash
# TeammateIdle hook: quality gate before teammate stops
# Exit 0 = allow idle, Exit 2 = block with feedback
#
# Solo mode: always allows (exit 0)
# Teammate mode: runs version check + test pass verification

set -euo pipefail

# Kill switch: skip all hooks
if [ "${QUANTDEV_DISABLE_HOOKS:-}" = "true" ]; then exit 0; fi
# Selective skip: comma-separated hook names
HOOK_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
if [[ ",${QUANTDEV_SKIP_HOOKS:-}," == *",$HOOK_NAME,"* ]]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/team-detect.sh"

# Solo mode: skip gates
if [ "${QUANTDEV_IS_TEAMMATE}" != "true" ]; then
    exit 0
fi

# Gate 1: Version check
if [ -f "${SCRIPT_DIR}/scripts/check-versions.sh" ]; then
    if ! _output=$(bash "${SCRIPT_DIR}/scripts/check-versions.sh" 2>&1); then
        echo "BLOCKED: Version check failed. Fix version mismatches before stopping." >&2
        echo "$_output" | tail -5 >&2
        exit 2
    fi
fi

# Gate 2: Tests must pass
if ! _output=$(npm test --prefix "${SCRIPT_DIR}" 2>&1); then
    echo "BLOCKED: Tests are failing. Fix test failures before stopping." >&2
    echo "$_output" | tail -10 >&2
    exit 2
fi

# Gate 3: Trading quality gates (only when .quantdev exists in project)
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

if [ -d "${PROJECT_DIR}/.quantdev" ]; then
    # Cross-platform validation: check if indicator golden files are stale
    if [ -d "${PROJECT_DIR}/.quantdev/validation/golden" ]; then
        # Find indicators modified more recently than their golden expected output
        stale_indicators=""
        for golden_dir in "${PROJECT_DIR}"/.quantdev/validation/golden/*/; do
            [ -d "$golden_dir" ] || continue
            indicator_name=$(basename "$golden_dir")
            expected_file="${golden_dir}expected.csv"
            [ -f "$expected_file" ] || continue
            expected_mtime=$(stat -f %m "$expected_file" 2>/dev/null || stat -c %Y "$expected_file" 2>/dev/null || echo "0")
            # Check if any indicator source file is newer than the golden file
            for src in "${PROJECT_DIR}"/indicators/"${indicator_name}"/*; do
                [ -f "$src" ] || continue
                src_mtime=$(stat -f %m "$src" 2>/dev/null || stat -c %Y "$src" 2>/dev/null || echo "0")
                if [ "$src_mtime" -gt "$expected_mtime" ] 2>/dev/null; then
                    stale_indicators="${stale_indicators} ${indicator_name}"
                    break
                fi
            done
        done
        if [ -n "$stale_indicators" ]; then
            echo "WARNING: Indicator source files modified after golden validation:${stale_indicators}" >&2
            echo "Run /quantdev:validate to update cross-platform validation." >&2
            # Warning only, don't block
        fi
    fi

    # Regression baselines: check if strategy baselines exist and are recent
    if [ -d "${PROJECT_DIR}/.quantdev/strategies" ]; then
        for strategy_dir in "${PROJECT_DIR}"/.quantdev/strategies/*/; do
            [ -d "$strategy_dir" ] || continue
            strategy_name=$(basename "$strategy_dir")
            if [ -d "${strategy_dir}backtests" ]; then
                backtest_count=$(find "${strategy_dir}backtests" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
                if [ "$backtest_count" -eq 0 ]; then
                    echo "WARNING: Strategy '${strategy_name}' has no backtest results. Run /quantdev:backtest." >&2
                fi
            fi
        done
    fi
fi

exit 0
