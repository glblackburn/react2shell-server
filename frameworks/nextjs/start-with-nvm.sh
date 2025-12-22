#!/bin/bash
set -e

# Source nvm if available
if [ -s "$HOME/.nvm/nvm.sh" ] && [ -f .nvmrc ]; then
    . "$HOME/.nvm/nvm.sh"
    nvm use >/dev/null 2>&1
fi

# Run npm dev
exec npm run dev
