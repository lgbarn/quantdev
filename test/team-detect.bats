#!/usr/bin/env bats
load test_helper

# --- Team detection tests ---

# bats test_tags=unit
@test "team-detect: no env vars sets all false" {
    (
        unset CLAUDE_CODE_TEAM_NAME 2>/dev/null || true
        unset CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 2>/dev/null || true
        source "$TEAM_DETECT"
        [ "$QUANTDEV_IS_TEAMMATE" = "false" ]
        [ "$QUANTDEV_TEAM_NAME" = "" ]
    )
}

# bats test_tags=unit
@test "team-detect: CLAUDE_CODE_TEAM_NAME set exports QUANTDEV_IS_TEAMMATE=true" {
    (
        export CLAUDE_CODE_TEAM_NAME="my-team"
        source "$TEAM_DETECT"
        [ "$QUANTDEV_IS_TEAMMATE" = "true" ]
        [ "$QUANTDEV_TEAM_NAME" = "my-team" ]
    )
}

# bats test_tags=unit
@test "team-detect: both env vars set activates teammate and team name" {
    (
        export CLAUDE_CODE_TEAM_NAME="alpha-team"
        export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"
        source "$TEAM_DETECT"
        [ "$QUANTDEV_IS_TEAMMATE" = "true" ]
        [ "$QUANTDEV_TEAM_NAME" = "alpha-team" ]
    )
}

# bats test_tags=unit
@test "team-detect: CLAUDE_CODE_TEAM_NAME empty string is not teammate" {
    (
        export CLAUDE_CODE_TEAM_NAME=""
        source "$TEAM_DETECT"
        [ "$QUANTDEV_IS_TEAMMATE" = "false" ]
        [ "$QUANTDEV_TEAM_NAME" = "" ]
    )
}

# bats test_tags=unit
@test "team-detect: ShellCheck clean" {
    command -v shellcheck &>/dev/null || skip "shellcheck not installed"
    run shellcheck --severity=warning "$TEAM_DETECT"
    assert_success
}
