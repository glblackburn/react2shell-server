#!/bin/bash
# Wrapper script to start Next.js dev server with nvm
# Usage: ./scripts/start-nextjs.sh [directory]

set -e

DIR="${1:-$(pwd)}"
cd "$DIR" || exit 1

# Source nvm if available
if [ -f ~/.nvm/nvm.sh ]; then
    export TERM=dumb
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

# Run npm dev server
exec npm run dev
