#!/usr/bin/env bash
# TaskCompleted hook: quality gate before marking task done
# Exit 0 = allow completion, Exit 2 = block with feedback
#
# Solo mode: always allows (exit 0)
# Teammate mode: verifies task has evidence (test output, results)

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

# Trading-specific evidence checks per track
# Detect current track from STATE.json or task metadata
current_track=""
if [ -f ".quantdev/STATE.json" ]; then
    current_track=$(jq -r '.track // ""' .quantdev/STATE.json 2>/dev/null || true)
fi

# Track-specific evidence requirements
if [ -n "$current_track" ]; then
    case "$current_track" in
        indicator)
            # Indicator track: validation must have run
            if [ -d ".quantdev/validation/golden" ]; then
                golden_count=$(find .quantdev/validation/golden -name "expected.csv" 2>/dev/null | wc -l | tr -d ' ')
                if [ "$golden_count" -eq 0 ]; then
                    echo "WARNING: Indicator track — no golden-file validation data found. Run /quantdev:validate." >&2
                fi
            fi
            ;;
        bot)
            # Bot track: tests must pass + lookahead check
            if command -v go >/dev/null 2>&1 && [ -f "go.mod" ]; then
                if ! go test ./... > /dev/null 2>&1; then
                    echo "BLOCKED: Bot track — Go tests failing. Fix tests before marking task complete." >&2
                    exit 2
                fi
            fi
            ;;
        research)
            # Research track: findings must be documented
            if [ -d ".quantdev/research" ]; then
                findings_count=$(find .quantdev/research -name "FINDINGS.md" 2>/dev/null | wc -l | tr -d ' ')
                if [ "$findings_count" -eq 0 ] && [ -d ".quantdev/strategies" ]; then
                    journal_count=$(find .quantdev/strategies -name "JOURNAL.md" 2>/dev/null | wc -l | tr -d ' ')
                    if [ "$journal_count" -eq 0 ]; then
                        echo "WARNING: Research track — no findings or journal entries found. Document results." >&2
                    fi
                fi
            fi
            ;;
    esac
fi

# Check for evidence: phase results or verification artifacts in .quantdev
if [ -d ".quantdev/phases" ]; then
    evidence_count=0
    # Scope evidence check to current phase directory
    current_phase=$(jq -r '.phase // ""' .quantdev/STATE.json 2>/dev/null || true)
    if [ -n "$current_phase" ]; then
        phase_dir=$(find .quantdev/phases/ -maxdepth 1 -type d \
            \( -name "${current_phase}*" -o -name "0${current_phase}*" \) 2>/dev/null | head -1)
        if [ -n "$phase_dir" ]; then
            evidence_count=$(find "$phase_dir" \
                \( -name "SUMMARY-*.md" -o -name "REVIEW-*.md" -o -name "AUDIT-*.md" \) \
                | wc -l | tr -d ' ')
        fi
    else
        # Fallback: no phase in state, check all phases
        evidence_count=$(find .quantdev/phases/ \
            \( -name "SUMMARY-*.md" -o -name "REVIEW-*.md" -o -name "AUDIT-*.md" \) \
            | wc -l | tr -d ' ')
    fi
    if [ "${evidence_count}" -gt 0 ]; then
        # Verify at least one evidence file has non-trivial content (>3 lines)
        has_substance=false
        while IFS= read -r efile; do
            if [ "$(wc -l < "$efile" | tr -d ' ')" -gt 3 ]; then
                has_substance=true
                break
            fi
        done < <(find "${phase_dir:-.quantdev/phases/}" \
            \( -name "SUMMARY-*.md" -o -name "REVIEW-*.md" -o -name "AUDIT-*.md" \) 2>/dev/null)
        if [ "$has_substance" = true ]; then
            exit 0
        fi
        echo "BLOCKED: Evidence files exist but none have substantive content (>3 lines). Add real verification results." >&2
        exit 2
    fi
fi

echo "BLOCKED: No verification evidence found. Run tests and produce results before marking task complete." >&2
exit 2
