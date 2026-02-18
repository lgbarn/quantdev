#!/usr/bin/env bash
# Team detection utility
# Source this script to detect Claude Code Agent Teams environment.
# Exports: QUANTDEV_IS_TEAMMATE, QUANTDEV_TEAM_NAME
#
# Usage: source scripts/team-detect.sh

# Detect if running as a teammate (Claude Code sets CLAUDE_CODE_TEAM_NAME automatically)
if [ -n "${CLAUDE_CODE_TEAM_NAME:-}" ]; then
    export QUANTDEV_IS_TEAMMATE=true
    export QUANTDEV_TEAM_NAME="$CLAUDE_CODE_TEAM_NAME"
else
    export QUANTDEV_IS_TEAMMATE=false
    export QUANTDEV_TEAM_NAME=""
fi
