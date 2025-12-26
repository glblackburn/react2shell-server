#!/usr/bin/env bash
# Helper script to run commands and save output to timestamped files in /tmp/

set -euET -o pipefail

# Usage: save_command_output.sh <command_name> <command>
# Example: save_command_output.sh "test_nextjs" "make test-nextjs-startup"

COMMAND_NAME="${1:-command}"
shift
COMMAND="$@"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 <command_name> <command>"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="/tmp/${COMMAND_NAME}_${TIMESTAMP}.txt"

echo "Running: $COMMAND"
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

# Run command and save output
eval "$COMMAND" 2>&1 | tee "$OUTPUT_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "Command completed with exit code: $EXIT_CODE"
echo "Output saved to: $OUTPUT_FILE"
echo "File size: $(wc -l < "$OUTPUT_FILE" | xargs) lines"

exit $EXIT_CODE
