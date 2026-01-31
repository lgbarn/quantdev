#!/usr/bin/env bash
# SessionStart hook for Quantdev plugin
# Reads project state and injects context at session start
# Supports adaptive context loading (minimal/planning/execution/brownfield/full)
#
# Exit Codes:
#   0 - Success (JSON context output produced)
#   1 - User error (invalid tier value -- currently auto-corrected, reserved for future use)
#   2 - State corruption (STATE.json missing required fields or malformed)
#   3 - Missing dependency (jq not found)

set -euo pipefail

# Sanitize lesson content — defense-in-depth, NOT a security boundary.
# LESSONS.md is local user-edited content, not external/untrusted input.
# This catches accidental prompt pollution (stray XML tags, copy-pasted
# system prompts). It will NOT stop a determined adversary — regex-based
# sanitization is inherently bypassable. The real protection is that
# .quantdev/ is local-only and gitignored.
# Strips XML/HTML tags, code blocks, prompt directives, and caps length.
sanitize_lesson() {
    local raw="$1"
    # 1. Strip XML/HTML tags (closed and unclosed) and HTML-encoded tag entities
    raw=$(printf '%s\n' "$raw" | sed 's/<[^>]*>//g; s/<[a-zA-Z\/!][^>]*$//g; s/&lt;/ /g; s/&gt;/ /g; s/&#60;/ /g; s/&#62;/ /g')
    # 2. Remove code blocks (lines between triple-backtick fences, inclusive)
    raw=$(printf '%s\n' "$raw" | awk '/```/{skip=!skip; next} !skip{print}')
    # 3. Filter lines containing prompt directive patterns (case-insensitive)
    raw=$(printf '%s\n' "$raw" | grep -viE '^\s*(SYSTEM|ASSISTANT|USER)\s*:|\bSYSTEM\s+PROMPT\b|\bIGNORE\s+(ALL\s+)?(PREVIOUS|ABOVE)\b|\bNEW\s+INSTRUCTION\b' || true)
    # 4. Cap at 500 characters
    if [ "${#raw}" -gt 500 ]; then
        raw="${raw:0:497}..."
    fi
    printf '%s' "$raw"
}

# Auto-migrate STATE.md to STATE.json + HISTORY.md
# Called when STATE.json is missing but STATE.md exists
migrate_state_md() {
    local state_md
    state_md=$(cat ".quantdev/STATE.md" 2>/dev/null || echo "")

    # Validate required fields (same checks as legacy code)
    if [ -z "$state_md" ]; then
        jq -n '{
            error: "STATE.md is corrupt or incomplete",
            details: "File is empty",
            exitCode: 2,
            recovery: "Run: bash scripts/state-write.sh --recover"
        }'
        exit 2
    fi
    local local_missing=""
    echo "$state_md" | grep -q '\*\*Status:\*\*' || local_missing="Status"
    echo "$state_md" | grep -q '\*\*Current Phase:\*\*' || local_missing="${local_missing:+$local_missing, }Current Phase"
    if [ -n "$local_missing" ]; then
        jq -n --arg missing "$local_missing" '{
            error: "STATE.md is corrupt or incomplete",
            details: ("Missing required field(s): " + $missing),
            exitCode: 2,
            recovery: "Run: bash scripts/state-write.sh --recover"
        }'
        exit 2
    fi

    # Extract fields
    local m_status m_phase m_position m_blocker m_updated
    m_status=$(echo "$state_md" | sed -n 's/^.*\*\*Status:\*\* \(.*\)$/\1/p' | head -1)
    m_phase=$(echo "$state_md" | sed -n 's/^.*\*\*Current Phase:\*\* \([0-9][0-9]*\).*$/\1/p' | head -1)
    m_position=$(echo "$state_md" | sed -n 's/^.*\*\*Current Position:\*\* \(.*\)$/\1/p' | head -1)
    m_blocker=$(echo "$state_md" | sed -n 's/^.*\*\*Blocker:\*\* \(.*\)$/\1/p' | head -1)
    m_updated=$(echo "$state_md" | sed -n 's/^.*\*\*Last Updated:\*\* \(.*\)$/\1/p' | head -1)
    m_updated="${m_updated:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"

    # Validate phase integer
    if [ -n "$m_phase" ] && ! [[ "$m_phase" =~ ^[0-9]+$ ]]; then
        m_phase="0"
    fi

    # Write STATE.json
    jq -n \
        --argjson schema 3 \
        --argjson phase "${m_phase:-0}" \
        --arg position "${m_position:-}" \
        --arg status "${m_status:-unknown}" \
        --arg updated_at "$m_updated" \
        --arg blocker "${m_blocker:-}" \
        '{schema: $schema, phase: $phase, position: $position, status: $status, updated_at: $updated_at, blocker: (if $blocker == "" then null else $blocker end)}' \
        > .quantdev/STATE.json

    # Extract history section from STATE.md and write HISTORY.md
    local history_section=""
    history_section=$(echo "$state_md" | sed -n '/^## History$/,$ { /^## History$/d; p; }' | sed '/^$/d')
    if [ -n "$history_section" ]; then
        printf '%s\n' "$history_section" > .quantdev/HISTORY.md
    fi
    # Append migration log entry
    printf '%s\n' "- [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Migrated from STATE.md to STATE.json (schema 3)" >> .quantdev/HISTORY.md

    echo "Migrated STATE.md -> STATE.json + HISTORY.md" >&2
}

# Parse arguments
HUMAN_MODE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --human) HUMAN_MODE=true; shift ;;
        *) shift ;;
    esac
done

# Check for jq dependency
if ! command -v jq >/dev/null 2>&1; then
    echo '{"error":"Missing dependency: jq is required but not found in PATH","exitCode":3}' >&2
    exit 3
fi

# Build compact skill summary from discovered skills (auto-discovers from skills/*/SKILL.md)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

skill_list=""
for skill_dir in "${PLUGIN_ROOT}"/skills/*/; do
    [ -f "${skill_dir}SKILL.md" ] || continue
    skill_name=$(basename "$skill_dir")
    # Extract first line description from SKILL.md (after the # header)
    desc=$(sed -n '/^[^#]/{ s/^[[:space:]]*//; p; q; }' "${skill_dir}SKILL.md" 2>/dev/null || echo "")
    [ -z "$desc" ] && desc="(no description)"
    # Truncate long descriptions
    [ "${#desc}" -gt 120 ] && desc="${desc:0:117}..."
    skill_list="${skill_list}\n- \`quantdev:${skill_name}\` - ${desc}"
done

read -r -d '' skill_summary <<SKILLEOF || true
## Quantdev Skills & Commands

**Skills** (invoke via Skill tool for full details):
$(printf '%b' "$skill_list")

**Triggers:** File patterns (*.tf, Dockerfile, *.test.*), task markers (tdd="true"), state conditions (claiming done, errors), and content patterns (security, refactor) activate skills automatically. If even 1% chance a skill applies, invoke it.

**Commands:** /init, /status, /resume, /recover, /rollback, /indicator, /validate, /port, /bot, /deploy, /backtest, /optimize, /research, /review, /risk, /map, /debug, /quick, /help
SKILLEOF

# Build state context
state_context=""
suggestion=""

# Reject symlinked .quantdev directory (security: prevent writes outside project)
if [ -L ".quantdev" ]; then
    jq -n '{
        error: ".quantdev is a symlink, which is not allowed",
        details: "Remove the symlink and run /quantdev:init to create a real directory",
        recovery: "rm .quantdev && mkdir .quantdev"
    }'
    exit 3
fi

if [ -d ".quantdev" ]; then
    if [ -f ".quantdev/STATE.json" ]; then
        # PRIMARY PATH: Read STATE.json via jq
        :
    elif [ -f ".quantdev/STATE.md" ]; then
        # MIGRATION PATH: Convert STATE.md -> STATE.json + HISTORY.md
        migrate_state_md
        # Fall through to read the newly-created STATE.json
    fi

    if [ -f ".quantdev/STATE.json" ]; then
        # Verify integrity: checksum + JSON validation
        _state_ok=true

        # Checksum verification (if checksum file exists)
        if [ -f ".quantdev/STATE.json.sha256" ]; then
            _expected_sum=$(cat ".quantdev/STATE.json.sha256" 2>/dev/null || echo "")
            _actual_sum=$(shasum -a 256 .quantdev/STATE.json | cut -d' ' -f1)
            if [ -n "$_expected_sum" ] && [ "$_expected_sum" != "$_actual_sum" ]; then
                _state_ok=false
            fi
        fi

        # JSON structure validation
        if [ "$_state_ok" = true ]; then
            jq -e 'has("schema") and has("phase") and has("status")' .quantdev/STATE.json > /dev/null 2>&1 || _state_ok=false
        fi

        # Fallback to backup if primary is corrupt
        if [ "$_state_ok" = false ]; then
            if [ -f ".quantdev/STATE.json.bak" ] && \
               jq -e 'has("schema") and has("phase") and has("status")' .quantdev/STATE.json.bak > /dev/null 2>&1; then
                cp ".quantdev/STATE.json.bak" ".quantdev/STATE.json"
                shasum -a 256 ".quantdev/STATE.json" | cut -d' ' -f1 > ".quantdev/STATE.json.sha256" 2>/dev/null || true
            else
                jq -n '{
                    error: "STATE.json is corrupt or incomplete",
                    details: "Malformed JSON or missing required fields (schema, phase, status)",
                    exitCode: 2,
                    recovery: "Run: bash scripts/state-write.sh --recover"
                }'
                exit 2
            fi
        fi

        # Extract fields in one jq call (IFS=tab because position/blocker may contain spaces)
        _tsv=$(jq -r '[.schema, .phase, .status, (.position // ""), (.blocker // "")] | @tsv' .quantdev/STATE.json 2>/dev/null) || {
            jq -n '{
                error: "Failed to extract fields from STATE.json",
                details: "JSON may be structurally valid but contains incompatible field types",
                recovery: "Run: bash scripts/state-write.sh --recover"
            }'
            exit 2
        }
        IFS=$'\t' read -r schema phase status position blocker <<< "$_tsv"

        # Validate phase is a pure integer
        if [ -n "$phase" ] && ! [[ "$phase" =~ ^[0-9]+$ ]]; then
            phase=""
        fi

        # Determine context tier from config (default: auto)
        context_tier="auto"
        if [ -f ".quantdev/config.json" ]; then
            context_tier=$(jq -r '.context_tier // "auto"' ".quantdev/config.json" 2>/dev/null || echo "auto")
        fi
        case "$context_tier" in
            auto|minimal|planning|execution|brownfield|full) ;;
            *) context_tier="auto" ;;
        esac

        # Auto-detect tier based on status
        if [ "$context_tier" = "auto" ]; then
            case "$status" in
                building|in_progress) context_tier="execution" ;;
                planning|planned|ready|shipped|complete|"") context_tier="planning" ;;
                *) context_tier="planning" ;;
            esac
        fi

        # Render structured STATE.json context (replaces raw STATE.md dump)
        state_context="## Quantdev Project State Detected\n\nA .quantdev/ directory exists in this project. Below is the current state.\n\n### STATE.json\nPhase: ${phase}\nStatus: ${status}\nPosition: ${position:-none}\nBlocker: ${blocker:-none}\nSchema: ${schema}\n"

        # Planning tier and above: load PROJECT.md + ROADMAP.md
        if [ "$context_tier" != "minimal" ]; then
            if [ -f ".quantdev/PROJECT.md" ]; then
                project_md=$(cat ".quantdev/PROJECT.md" 2>/dev/null || echo "")
                if [ -n "$project_md" ]; then
                    state_context="${state_context}\n### PROJECT.md (summary)\n${project_md}\n"
                fi
            fi
            if [ -f ".quantdev/ROADMAP.md" ]; then
                roadmap_summary=$(head -80 ".quantdev/ROADMAP.md" 2>/dev/null || echo "")
                if [ -n "$roadmap_summary" ]; then
                    state_context="${state_context}\n### ROADMAP.md (first 80 lines)\n${roadmap_summary}\n"
                fi
            fi
        fi

        # Execution tier: also load current phase plans and recent summaries
        if [ "$context_tier" = "execution" ] || [ "$context_tier" = "full" ]; then
            if [ -n "$phase" ]; then
                # Find phase directory (handles zero-padded names like 01-name)
                if [ -d ".quantdev/phases" ]; then
                    phase_dir=$(find .quantdev/phases/ -maxdepth 1 -type d \( -name "${phase}*" -o -name "0${phase}*" \) 2>/dev/null | head -1)
                else
                    phase_dir=""
                fi
                if [ -n "$phase_dir" ]; then
                    plan_context=""
                    # Load plans (first 50 lines each, max 3)
                    if [ -d "${phase_dir}/plans" ]; then
                        plan_count=0
                        for plan_file in "${phase_dir}/plans/"PLAN-*.md; do
                            [ -e "$plan_file" ] || continue
                            [ "$plan_count" -ge 3 ] && break
                            plan_count=$((plan_count + 1))
                            plan_snippet=$(head -50 "$plan_file" 2>/dev/null || echo "")
                            plan_context="${plan_context}\n#### $(basename "$plan_file")\n${plan_snippet}\n"
                        done
                    fi
                    # Load recent summaries (first 30 lines each, max 3)
                    summary_files=()
                    if [ -d "${phase_dir}/results" ]; then
                        for f in "${phase_dir}/results/"SUMMARY-*.md; do
                            [ -e "$f" ] && summary_files+=("$f")
                        done
                    fi
                    # Take last 3 entries (glob sorts lexicographically)
                    total=${#summary_files[@]}
                    start=$(( total > 3 ? total - 3 : 0 ))
                    for summary_file in "${summary_files[@]:$start}"; do
                        summary_snippet=$(head -30 "$summary_file" 2>/dev/null || echo "")
                        plan_context="${plan_context}\n#### $(basename "$summary_file")\n${summary_snippet}\n"
                    done
                    if [ -n "$plan_context" ]; then
                        state_context="${state_context}\n### Current Phase Context\n${plan_context}\n"
                    fi
                fi
            fi

            # Load recent lessons (execution/full tier only, max 5)
            if [ -f ".quantdev/LESSONS.md" ]; then
                lesson_headers=$(grep -n "^## \[" ".quantdev/LESSONS.md" 2>/dev/null || echo "")
                if [ -n "$lesson_headers" ]; then
                    last_five=$(echo "$lesson_headers" | tail -5)
                    lesson_snippet=""
                    while IFS=: read -r line_num _; do
                        # Extract header + ~7 lines of lesson content (8 lines total per lesson)
                        chunk=$(sed -n "${line_num},$((line_num + 8))p" ".quantdev/LESSONS.md" 2>/dev/null || echo "")
                        chunk=$(sanitize_lesson "$chunk")
                        lesson_snippet="${lesson_snippet}${chunk}\n"
                    done <<< "$last_five"
                    if [ -n "$lesson_snippet" ]; then
                        state_context="${state_context}\n### Recent Lessons Learned\n${lesson_snippet}\n"
                    fi
                fi
            fi

            # Load recent history (execution/full tier only)
            if [ -f ".quantdev/HISTORY.md" ]; then
                history_tail=$(tail -10 ".quantdev/HISTORY.md" 2>/dev/null || echo "")
                if [ -n "$history_tail" ]; then
                    state_context="${state_context}\n### Recent History\n${history_tail}\n"
                fi
            fi

            # Load working notes (execution/full tier only, last 20 lines)
            if [ -f ".quantdev/NOTES.md" ]; then
                notes_tail=$(tail -20 ".quantdev/NOTES.md" 2>/dev/null || echo "")
                if [ -n "$notes_tail" ]; then
                    state_context="${state_context}\n### Working Notes\n${notes_tail}\n"
                fi
            fi
        fi

        # Trading context: load strategies, recent backtests, knowledge base
        if [ "$context_tier" = "execution" ] || [ "$context_tier" = "full" ]; then
            # Load knowledge base (trading insights)
            if [ -f ".quantdev/KNOWLEDGE.md" ]; then
                knowledge_snippet=$(head -40 ".quantdev/KNOWLEDGE.md" 2>/dev/null || echo "")
                if [ -n "$knowledge_snippet" ]; then
                    state_context="${state_context}\n### Knowledge Base (first 40 lines)\n${knowledge_snippet}\n"
                fi
            fi

            # Load active strategies summary
            if [ -d ".quantdev/strategies" ]; then
                strategy_summary=""
                for strat_dir in .quantdev/strategies/*/; do
                    [ -d "$strat_dir" ] || continue
                    strat_name=$(basename "$strat_dir")
                    # Get latest backtest result summary
                    latest_backtest=""
                    if [ -d "${strat_dir}backtests" ]; then
                        latest_file=$(find "${strat_dir}backtests" -name "*.json" -type f 2>/dev/null | sort | tail -1)
                        if [ -n "$latest_file" ] && command -v jq >/dev/null 2>&1; then
                            pf=$(jq -r '.profit_factor // .pf // "?"' "$latest_file" 2>/dev/null || echo "?")
                            sharpe=$(jq -r '.sharpe // .sharpe_ratio // "?"' "$latest_file" 2>/dev/null || echo "?")
                            trades=$(jq -r '.trade_count // .total_trades // "?"' "$latest_file" 2>/dev/null || echo "?")
                            latest_backtest=" | Last backtest: PF=${pf} Sharpe=${sharpe} Trades=${trades}"
                        fi
                    fi
                    # Check for hypothesis
                    hypothesis=""
                    if [ -f "${strat_dir}HYPOTHESIS.md" ]; then
                        hypothesis=$(head -3 "${strat_dir}HYPOTHESIS.md" 2>/dev/null | tail -1)
                        [ -n "$hypothesis" ] && hypothesis=" — ${hypothesis}"
                    fi
                    strategy_summary="${strategy_summary}\n- **${strat_name}**${hypothesis}${latest_backtest}"
                done
                if [ -n "$strategy_summary" ]; then
                    state_context="${state_context}\n### Active Strategies${strategy_summary}\n"
                fi
            fi

            # Load recent research topics
            if [ -d ".quantdev/research" ]; then
                research_topics=""
                for res_dir in .quantdev/research/*/; do
                    [ -d "$res_dir" ] || continue
                    topic_name=$(basename "$res_dir")
                    findings_status="in progress"
                    [ -f "${res_dir}FINDINGS.md" ] && findings_status="complete"
                    research_topics="${research_topics}\n- ${topic_name} (${findings_status})"
                done
                if [ -n "$research_topics" ]; then
                    state_context="${state_context}\n### Research Topics${research_topics}\n"
                fi
            fi
        fi

        # Brownfield/full tier: also load codebase analysis
        if [ "$context_tier" = "full" ]; then
            # Read codebase docs path from config (default: .quantdev/codebase)
            codebase_docs_path=".quantdev/codebase"
            if [ -f ".quantdev/config.json" ]; then
                codebase_docs_path=$(jq -r '.codebase_docs_path // ".quantdev/codebase"' ".quantdev/config.json" 2>/dev/null || echo ".quantdev/codebase")
            fi
            # Validate: reject absolute paths and directory traversals
            case "$codebase_docs_path" in
                /*|*..*) codebase_docs_path=".quantdev/codebase" ;;
            esac

            if [ -d "$codebase_docs_path" ]; then
                codebase_context=""
                for doc in STACK.md ARCHITECTURE.md CONVENTIONS.md CONCERNS.md; do
                    if [ -f "${codebase_docs_path}/$doc" ]; then
                        doc_snippet=$(head -40 "${codebase_docs_path}/$doc" 2>/dev/null || echo "")
                        codebase_context="${codebase_context}\n#### ${doc}\n${doc_snippet}\n"
                    fi
                done
                if [ -n "$codebase_context" ]; then
                    state_context="${state_context}\n### Codebase Analysis\n${codebase_context}\n"
                fi
            fi
        fi

        # Command auto-suggestions based on current state
        case "$status" in
            ready)
                suggestion="**Suggested next step:** \`/quantdev:plan ${phase:-1}\` -- Plan the current phase"
                ;;
            planned)
                suggestion="**Suggested next step:** \`/quantdev:build ${phase:-1}\` -- Execute the planned phase"
                ;;
            planning)
                suggestion="**Suggested next step:** Continue planning or run \`/quantdev:status\` to check progress"
                ;;
            building|in_progress)
                suggestion="**Suggested next step:** \`/quantdev:resume\` -- Continue building"
                ;;
            complete|complete_with_gaps)
                # Check if more phases exist
                next_phase=$((${phase:-0} + 1))
                if grep -qE "Phase ${next_phase}|Phase 0${next_phase}" ".quantdev/ROADMAP.md" 2>/dev/null; then
                    suggestion="**Suggested next step:** \`/quantdev:plan ${next_phase}\` -- Plan the next phase"
                else
                    suggestion="**Suggested next step:** \`/quantdev:ship\` -- All phases complete, ready to deliver"
                fi
                ;;
            shipped)
                suggestion="**Project shipped!** Run \`/quantdev:init\` to start a new milestone."
                ;;
        esac

        # Check for open issues
        if [ -f ".quantdev/ISSUES.md" ]; then
            issue_count=$(grep -c "^|" ".quantdev/ISSUES.md" 2>/dev/null || echo "0")
            # Subtract header rows (2 per table section)
            issue_count=$((issue_count > 4 ? issue_count - 4 : 0))
            if [ "$issue_count" -gt 0 ]; then
                suggestion="${suggestion}\n**Note:** ${issue_count} tracked issue(s). Run \`/quantdev:issues\` to review."
            fi
        fi

        # Add suggestion and commands to context
        if [ -n "$suggestion" ]; then
            state_context="${state_context}\n### Recommended Action\n${suggestion}\n"
        fi
    fi
fi

if [ -z "$state_context" ]; then
    state_context="## No Quantdev Project Detected\n\nThis project does not have a .quantdev/ directory.\n\n**To get started, the user can run:** /quantdev:init\n\nThis will analyze the codebase (if one exists), gather requirements, and create a structured roadmap.\n"
fi

# Combine all context
full_context="<EXTREMELY_IMPORTANT>\nYou have Quantdev available -- a structured project execution framework.\n\n**Current State:**\n${state_context}\n\n**Below are available Quantdev skills and commands. Use the Skill tool to load any skill for full details.**\n\n${skill_summary}\n</EXTREMELY_IMPORTANT>"

# Human-readable output mode (--human flag)
if [ "$HUMAN_MODE" = true ]; then
    if [ -f ".quantdev/STATE.json" ]; then
        _h_phase=$(jq -r '.phase' .quantdev/STATE.json)
        _h_status=$(jq -r '.status' .quantdev/STATE.json)
        _h_position=$(jq -r '.position // "none"' .quantdev/STATE.json)
        _h_updated=$(jq -r '.updated_at // "unknown"' .quantdev/STATE.json)
        _h_blocker=$(jq -r '.blocker // empty' .quantdev/STATE.json 2>/dev/null || true)
        echo "=== Quantdev State ==="
        echo "Phase:    ${_h_phase}"
        echo "Status:   ${_h_status}"
        echo "Position: ${_h_position}"
        echo "Updated:  ${_h_updated}"
        [ -n "$_h_blocker" ] && echo "Blocker:  ${_h_blocker}"
        echo ""
        if [ -f ".quantdev/HISTORY.md" ]; then
            echo "=== Recent History ==="
            tail -5 ".quantdev/HISTORY.md" 2>/dev/null || true
            echo ""
        fi
        echo "=== Suggested Action ==="
        case "$_h_status" in
            ready)                       echo "Run: /quantdev:plan ${_h_phase}" ;;
            planned)                     echo "Run: /quantdev:build ${_h_phase}" ;;
            planning)                    echo "Continue planning or run /quantdev:status" ;;
            building|in_progress)        echo "Run: /quantdev:resume" ;;
            complete|complete_with_gaps) echo "Run: /quantdev:plan $((_h_phase + 1)) or /quantdev:ship" ;;
            shipped)                     echo "Project shipped! Run /quantdev:init for new milestone" ;;
            *)                           echo "Run: /quantdev:status" ;;
        esac
    else
        echo "No Quantdev project detected. Run /quantdev:init to get started."
    fi
    exit 0
fi

# Output JSON (jq handles escaping natively)
jq -n --arg ctx "$full_context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

exit 0
