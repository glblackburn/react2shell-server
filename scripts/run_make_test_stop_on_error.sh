#!/bin/bash
# run_make_test_stop_on_error.sh
# 
# Runs tests and stops immediately at the first error or failure.
# Uses pytest's -x flag to stop at first failure.
# Captures all output and exits with error code if any failure occurs.
#
# Usage:
#   ./scripts/run_make_test_stop_on_error.sh [OUTPUT_DIR]
#
# If OUTPUT_DIR is not provided, creates a timestamped directory in /tmp/

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get output directory
if [ -n "${1:-}" ]; then
    OUTPUT_DIR="$1"
else
    OUTPUT_DIR="/tmp/make-test-fix-$(date +%Y-%m-%d-%H%M%S)"
fi

# Create directory structure
mkdir -p "$OUTPUT_DIR"/{output,files-before,files-after,logs,reports,artifacts,summary,iterations}

echo "=== Test Execution with Stop-on-First-Error ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

# Change to project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# Capture before state
echo "Capturing initial state..."
ps aux | grep -E "(node|npm|next|vite)" | grep -v grep > "$OUTPUT_DIR/files-before/processes-before.txt" 2>&1 || echo "No node processes" > "$OUTPUT_DIR/files-before/processes-before.txt"
netstat -an | grep LISTEN | grep -E "\.300[0-9]|\.5173" > "$OUTPUT_DIR/files-before/ports-before.txt" 2>&1 || echo "No test ports in use" > "$OUTPUT_DIR/files-before/ports-before.txt"
cat .framework-mode > "$OUTPUT_DIR/files-before/framework-mode-before.txt" 2>&1 || echo "No .framework-mode file" > "$OUTPUT_DIR/files-before/framework-mode-before.txt"
make status > "$OUTPUT_DIR/files-before/server-status-before.txt" 2>&1
(ls -la .pids/ .logs/ > "$OUTPUT_DIR/files-before/files-state-before.txt" 2>&1) || echo "No .pids or .logs dirs" > "$OUTPUT_DIR/files-before/files-state-before.txt"

# Capture metadata
{
    echo "Timestamp: $(date)"
    echo "Framework Mode: $(cat .framework-mode 2>/dev/null || echo 'not set')"
    echo "Python Version: $(python3 --version 2>&1)"
    echo "Node Version: $(node --version 2>&1)"
    echo "Working Directory: $(pwd)"
    echo "Script: $0"
} > "$OUTPUT_DIR/output/test-metadata.txt"

# Stop any running servers
echo "Stopping any running servers..."
make stop > /dev/null 2>&1 || true
sleep 2

# Determine pytest path
if [ -d "venv" ] && [ -f "venv/bin/pytest" ]; then
    PYTEST="venv/bin/pytest"
elif [ -f "tests/venv/bin/pytest" ]; then
    PYTEST="tests/venv/bin/pytest"
else
    PYTEST="pytest"
fi

# Check if pytest exists
if ! command -v "$PYTEST" >/dev/null 2>&1; then
    echo "❌ ERROR: pytest not found at $PYTEST"
    echo "   Run 'make test-setup' first to set up the test environment"
    exit 1
fi

# Check if servers are running, start if needed (framework-aware)
FRAMEWORK=$(cat .framework-mode 2>/dev/null || echo "vite")
if [ "$FRAMEWORK" = "nextjs" ]; then
    if ! lsof -ti:3000 >/dev/null 2>&1; then
        echo "⚠️  Server not running. Starting Next.js server..."
        make start > /dev/null 2>&1
        sleep 5
    fi
else
    if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then
        echo "⚠️  Servers not running. Starting servers..."
        make start > /dev/null 2>&1
        sleep 3
    fi
fi

# Run pytest with -x flag (stops at first failure)
echo ""
echo "=== Running tests (will stop at first error/failure) ==="
echo "Command: $PYTEST tests/ -v -x --tb=short --maxfail=1"
echo ""

START_TIME=$(date +%s)

# Run pytest and capture output
# -x: stop at first failure
# -v: verbose output  
# --tb=short: shorter traceback format
# --maxfail=1: stop after 1 failure (explicit)
# Redirect both stdout and stderr to file and also display
if $PYTEST tests/ -v -x --tb=short --maxfail=1 2>&1 | tee "$OUTPUT_DIR/output/make-test-live.txt"; then
    EXIT_CODE=0
else
    EXIT_CODE=$?
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Capture exit code and duration
echo $EXIT_CODE > "$OUTPUT_DIR/output/make-test-exitcode.txt"
echo "$DURATION seconds" > "$OUTPUT_DIR/output/make-test-duration.txt"

# Capture after state
echo ""
echo "Capturing final state..."
ps aux | grep -E "(node|npm|next|vite)" | grep -v grep > "$OUTPUT_DIR/files-after/processes-after.txt" 2>&1 || echo "No node processes" > "$OUTPUT_DIR/files-after/processes-after.txt"
netstat -an | grep LISTEN | grep -E "\.300[0-9]|\.5173" > "$OUTPUT_DIR/files-after/ports-after.txt" 2>&1 || echo "No test ports in use" > "$OUTPUT_DIR/files-after/ports-after.txt"
cat .framework-mode > "$OUTPUT_DIR/files-after/framework-mode-after.txt" 2>&1 || echo "No .framework-mode file" > "$OUTPUT_DIR/files-after/framework-mode-after.txt"
make status > "$OUTPUT_DIR/files-after/server-status-after.txt" 2>&1
(ls -la .pids/ .logs/ > "$OUTPUT_DIR/files-after/files-state-after.txt" 2>&1) || echo "No .pids or .logs dirs" > "$OUTPUT_DIR/files-after/files-state-after.txt"

# Copy logs
cp .logs/vite.log "$OUTPUT_DIR/logs/vite.log" 2>/dev/null || echo "No vite.log" > "$OUTPUT_DIR/logs/vite.log"
cp .logs/server.log "$OUTPUT_DIR/logs/server.log" 2>/dev/null || echo "No server.log" > "$OUTPUT_DIR/logs/server.log"

# Copy test reports if they exist
cp tests/reports/*.html "$OUTPUT_DIR/reports/" 2>/dev/null || true

# Summary
echo ""
echo "=== Test Execution Complete ==="
echo "Exit code: $EXIT_CODE"
echo "Duration: $DURATION seconds"
echo "Output directory: $OUTPUT_DIR"
echo ""

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ FAILED - Error or failure detected (stopped at first error)"
    echo ""
    echo "First error/failure found in: $OUTPUT_DIR/output/make-test-live.txt"
    echo ""
    echo "To view the error:"
    echo "  grep -A 20 'ERROR\\|FAILED\\|FAILURE' $OUTPUT_DIR/output/make-test-live.txt | head -50"
    echo ""
    exit 1
else
    echo "✅ SUCCESS - All tests passed"
    echo ""
    exit 0
fi
