#!/bin/bash
# Quick script to test what scopes a GitHub token has

if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.secure/github-set-token.sh ]; then
        source ~/.secure/github-set-token.sh
    fi
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN not set"
    exit 1
fi

echo "Testing token scopes..."
echo ""

# Get token information
response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user)

# Check if token is valid
if echo "$response" | grep -q '"login"'; then
    echo "✅ Token is valid"
    echo ""

    # Get scopes from response headers (GitHub returns scopes in X-OAuth-Scopes header)
    scopes=$(curl -s -I -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/user | grep -i "X-OAuth-Scopes" | cut -d' ' -f2- | tr -d '\r')

    if [ -n "$scopes" ]; then
        echo "Token scopes: $scopes"
        echo ""

        if echo "$scopes" | grep -q "repo"; then
            echo "✅ 'repo' scope is present - should work for branch protection"
        else
            echo "❌ 'repo' scope is NOT present - this is why you're getting 403 errors"
            echo ""
            echo "Required: Check the 'repo' scope in your token settings"
        fi
    else
        echo "⚠️  Could not determine scopes from response headers"
    fi
else
    echo "❌ Token is invalid or expired"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
fi
