#!/usr/bin/env bash
# Save GitHub Actions run logs to /tmp/ for analysis

set -euET -o pipefail

# Get the latest run or a specific run ID
RUN_ID="${1:-latest}"

if [ "$RUN_ID" = "latest" ]; then
    # Get latest run ID
    RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
    echo "Fetching latest run: $RUN_ID"
else
    echo "Fetching run: $RUN_ID"
fi

# Get run details
RUN_INFO=$(gh run view "$RUN_ID" --json status,conclusion,workflowName,headBranch,createdAt,displayTitle)
STATUS=$(echo "$RUN_INFO" | jq -r '.status')
CONCLUSION=$(echo "$RUN_INFO" | jq -r '.conclusion // "N/A"')
BRANCH=$(echo "$RUN_INFO" | jq -r '.headBranch')
WORKFLOW=$(echo "$RUN_INFO" | jq -r '.workflowName')
TITLE=$(echo "$RUN_INFO" | jq -r '.displayTitle')
TIMESTAMP=$(echo "$RUN_INFO" | jq -r '.createdAt' | sed 's/T/ /' | sed 's/Z//' | cut -d'.' -f1)

# Create filename
FILENAME="/tmp/github_actions_run_${RUN_ID}_$(echo "$TIMESTAMP" | sed 's/ /_/g' | sed 's/://g').txt"

echo "Saving GitHub Actions run log..."
echo "  Run ID: $RUN_ID"
echo "  Status: $STATUS"
echo "  Conclusion: $CONCLUSION"
echo "  Branch: $BRANCH"
echo "  Workflow: $WORKFLOW"
echo "  Title: $TITLE"
echo "  Output file: $FILENAME"
echo ""

# Save full log
gh run view "$RUN_ID" --log > "$FILENAME" 2>&1

echo "✓ Log saved to: $FILENAME"
echo "  File size: $(wc -l < "$FILENAME" | xargs) lines"

# Also save just the "Test Next.js Startup" job if it exists
if grep -q "Test Next.js Startup" "$FILENAME"; then
    NEXTJS_FILE="/tmp/github_actions_nextjs_job_${RUN_ID}_$(echo "$TIMESTAMP" | sed 's/ /_/g' | sed 's/://g').txt"
    # Extract the Test Next.js Startup job section
    awk '/Test Next.js Startup/,/^##\[group\]|^##\[endgroup\]|^##\[error\]|^##\[warning\]|^##\[notice\]|^##\[debug\]|^##\[section\]|^##\[command\]|^##\[endgroup\]/' "$FILENAME" > "$NEXTJS_FILE" || true
    if [ -s "$NEXTJS_FILE" ]; then
        echo "✓ Next.js job log saved to: $NEXTJS_FILE"
        echo "  File size: $(wc -l < "$NEXTJS_FILE" | xargs) lines"
    fi
fi
