#!/bin/bash
set -euET -o pipefail

TARGET_NAME="$1"
OUTPUT_DIR="$2"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

echo "=== Running target: $TARGET_NAME ==="
echo "Output directory: $OUTPUT_DIR"
echo "Timestamp: $TIMESTAMP"

# Capture file state before
find tests/ -type f -name "*.py" -o -name "*.html" -o -name "*.json" 2>/dev/null | sort > "$OUTPUT_DIR/files-before/${TARGET_NAME}-files-before.txt" || true
ps aux | grep -E "(node|python|vite|next)" | grep -v grep > "$OUTPUT_DIR/files-before/${TARGET_NAME}-processes-before.txt" || true

# Run the target and capture all output
START_TIME=$(date +%s)
if make "$TARGET_NAME" > "$OUTPUT_DIR/output/${TARGET_NAME}-stdout.txt" 2> "$OUTPUT_DIR/output/${TARGET_NAME}-stderr.txt"; then
    EXIT_CODE=0
else
    EXIT_CODE=$?
fi

# For test-parallel, wait for all child processes
if [ "$TARGET_NAME" = "test-parallel" ]; then
    echo "Waiting for background processes to complete..."
    MAX_WAIT=3600  # 1 hour maximum wait
    WAITED=0
    while [ $WAITED -lt $MAX_WAIT ]; do
        # Check for pytest processes
        if pgrep -f "pytest.*test" > /dev/null 2>&1; then
            if [ $((WAITED % 30)) -eq 0 ] && [ $WAITED -gt 0 ]; then
                echo "  Still waiting for pytest processes... (${WAITED}s elapsed)"
            fi
            sleep 5
            WAITED=$((WAITED + 5))
            continue
        fi
        # Check for run_version_tests_parallel.py
        if pgrep -f "run_version_tests_parallel.py" > /dev/null 2>&1; then
            if [ $((WAITED % 30)) -eq 0 ] && [ $WAITED -gt 0 ]; then
                echo "  Still waiting for version tests... (${WAITED}s elapsed)"
            fi
            sleep 5
            WAITED=$((WAITED + 5))
            continue
        fi
        # All processes completed
        break
    done
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "⚠️  Warning: Background processes still running after ${MAX_WAIT}s"
    else
        echo "✓ All background processes completed (${WAITED}s wait)"
    fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Capture file state after
find tests/ -type f -name "*.py" -o -name "*.html" -o -name "*.json" 2>/dev/null | sort > "$OUTPUT_DIR/files-after/${TARGET_NAME}-files-after.txt" || true
ps aux | grep -E "(node|python|vite|next)" | grep -v grep > "$OUTPUT_DIR/files-after/${TARGET_NAME}-processes-after.txt" || true

# Create combined output
cat "$OUTPUT_DIR/output/${TARGET_NAME}-stdout.txt" "$OUTPUT_DIR/output/${TARGET_NAME}-stderr.txt" > "$OUTPUT_DIR/output/${TARGET_NAME}-combined.txt"

# Save metadata
{
    echo "TARGET_NAME=$TARGET_NAME"
    echo "EXIT_CODE=$EXIT_CODE"
    echo "DURATION=$DURATION"
    echo "START_TIME=$START_TIME"
    echo "END_TIME=$END_TIME"
    echo "TIMESTAMP=$TIMESTAMP"
} > "$OUTPUT_DIR/output/${TARGET_NAME}-metadata.txt"

# Copy test reports if they exist
if [ -d "tests/reports" ]; then
    cp -r tests/reports/* "$OUTPUT_DIR/reports/" 2>/dev/null || true
fi

# Copy screenshots if they exist
if [ -d "tests/reports" ]; then
    find tests/reports -name "*.png" -exec cp {} "$OUTPUT_DIR/artifacts/" \; 2>/dev/null || true
fi

echo "=== Completed: $TARGET_NAME ==="
echo "Exit code: $EXIT_CODE"
echo "Duration: ${DURATION}s"
echo ""
