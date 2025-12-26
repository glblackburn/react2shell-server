#!/usr/bin/env bash
# Monitor GitHub Actions run and iterate on fixes until test-nextjs-startup works

set -euET -o pipefail

RUN_ID="${1:-latest}"
MAX_ITERATIONS="${2:-10}"
ITERATION=0

if [ "$RUN_ID" = "latest" ]; then
    RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
fi

echo "=== Monitoring GitHub Actions Run $RUN_ID ==="
echo "Will iterate up to $MAX_ITERATIONS times until test-nextjs-startup passes"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    echo "[Iteration $ITERATION] Checking run status..."
    
    # Get run status
    STATUS=$(gh run view "$RUN_ID" --json status,conclusion --jq '.status')
    CONCLUSION=$(gh run view "$RUN_ID" --json status,conclusion --jq '.conclusion // "N/A"')
    
    echo "  Status: $STATUS, Conclusion: $CONCLUSION"
    
    if [ "$STATUS" = "completed" ]; then
        echo ""
        echo "=== Run Completed ==="
        echo "Fetching full log..."
        
        # Save full log
        ./scripts/save_github_actions_log.sh "$RUN_ID" 2>&1 | tee "/tmp/monitor_iteration_${ITERATION}_${TIMESTAMP}.txt"
        
        # Check if Next.js test passed
        NEXTJS_JOB_LOG="/tmp/github_actions_nextjs_job_${RUN_ID}_*.txt"
        if ls $NEXTJS_JOB_LOG 1> /dev/null 2>&1; then
            NEXTJS_FILE=$(ls -t $NEXTJS_JOB_LOG | head -1)
            echo ""
            echo "=== Analyzing Next.js Startup Test ==="
            
            # Check for failures
            if grep -qi "failed\|error\|❌" "$NEXTJS_FILE"; then
                echo "❌ Test Next.js Startup job failed"
                echo ""
                echo "Analyzing failures..."
                grep -i "failed\|error\|❌" "$NEXTJS_FILE" | head -20
                echo ""
                echo "Full log: $NEXTJS_FILE"
                echo ""
                echo "=== Next Steps ==="
                echo "1. Review the log file: $NEXTJS_FILE"
                echo "2. Identify the root cause"
                echo "3. Make fixes"
                echo "4. Test locally: make test-nextjs-startup"
                echo "5. Commit and push"
                echo "6. Run this script again with new run ID"
                exit 1
            else
                echo "✓ Test Next.js Startup job passed!"
                echo "Full log: $NEXTJS_FILE"
                exit 0
            fi
        else
            echo "⚠️  Could not find Next.js job log"
            echo "Check full log for details"
            exit 1
        fi
    elif [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; then
        echo "  Run still in progress. Waiting 30 seconds..."
        sleep 30
    else
        echo "  Unexpected status: $STATUS"
        sleep 10
    fi
done

echo ""
echo "⚠️  Reached maximum iterations ($MAX_ITERATIONS)"
echo "Run may still be in progress. Check manually:"
echo "  gh run view $RUN_ID"
