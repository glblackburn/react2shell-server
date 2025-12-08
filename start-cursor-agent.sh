#!/bin/bash
#
# Cursor Agent Startup Script
#
# This script starts a Cursor IDE agent session with a specific resume ID.
# The agent allows for AI-assisted development workflows within Cursor IDE.
#
# Usage:
#   ./start-cursor-agent.sh
#   or
#   bash start-cursor-agent.sh
#
# Note: This requires Cursor IDE and the cursor-agent command to be installed
# and available in your PATH.
#
# The resume ID (b1c8137c-1e00-4f1d-9aa7-fa12c55071dc) is a session identifier
# that allows resuming a previous agent session.
#

set -euET -o pipefail

readonly RESUME_ID="b1c8137c-1e00-4f1d-9aa7-fa12c55071dc"

function check_cursor_agent {
    if ! command -v cursor-agent &> /dev/null; then
        echo "ERROR: cursor-agent command not found in PATH" >&2
        echo "Please ensure Cursor IDE is installed and cursor-agent is available" >&2
        return 1
    fi
}

function main {
    check_cursor_agent || return $?

    cursor-agent --resume="${RESUME_ID}" || {
        echo "ERROR: Failed to start cursor-agent" >&2
        return 1
    }
}

main "$@"
