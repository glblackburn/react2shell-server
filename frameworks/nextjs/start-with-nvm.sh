#!/bin/bash
set -e

# Next.js requires Node.js >= 20.9.0
REQUIRED_NODE_MAJOR=20
REQUIRED_NODE_MINOR=9

# Source nvm from standard or alternative location
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"
elif [ -s "$HOME/.config/nvm/nvm.sh" ]; then
    . "$HOME/.config/nvm/nvm.sh"
fi

# Use .nvmrc version if present and nvm is available
if command -v nvm >/dev/null 2>&1 || type nvm >/dev/null 2>&1; then
    if [ -f .nvmrc ]; then
        nvm use || nvm install
    fi
fi

# Verify Node version meets Next.js requirement (>= 20.9.0)
NODE_VER=$(node -v 2>/dev/null | sed -n 's/^v\([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
if [ -z "$NODE_VER" ]; then
    echo "Error: node not found. Install Node.js >= ${REQUIRED_NODE_MAJOR}.${REQUIRED_NODE_MINOR}.0 (e.g. run: make node)" >&2
    exit 1
fi
read MAJOR MINOR <<< "$NODE_VER"
if [ "$MAJOR" -lt "$REQUIRED_NODE_MAJOR" ] || { [ "$MAJOR" -eq "$REQUIRED_NODE_MAJOR" ] && [ "$MINOR" -lt "$REQUIRED_NODE_MINOR" ]; }; then
    echo "You are using Node.js $(node -v). For Next.js, Node.js version \">=${REQUIRED_NODE_MAJOR}.${REQUIRED_NODE_MINOR}.0\" is required." >&2
    echo "Run: make node   (or: nvm use, or set .nvmrc and nvm install)" >&2
    exit 1
fi

# Run npm dev
exec npm run dev
