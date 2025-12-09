#!/bin/bash
# Wrapper script to run commands with nvm if available
# Usage: ./scripts/run-with-nvm.sh <command> [args...]

if [ -f ~/.nvm/nvm.sh ]; then
    . ~/.nvm/nvm.sh
    # Prefer Node 18+ for Next.js compatibility
    if nvm list 18 2>/dev/null | grep -q "v18"; then
        nvm use 18 2>/dev/null || true
    elif nvm list 20 2>/dev/null | grep -q "v20"; then
        nvm use 20 2>/dev/null || true
    else
        nvm use default 2>/dev/null || nvm use node 2>/dev/null || true
    fi
fi

# Execute the command - don't use exec so the script stays alive for nohup
"$@"
