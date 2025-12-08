#!/usr/bin/env bash
set -euET -o pipefail

script_name=$(basename $0)
script_dir=$(dirname $0)

################################################################################
# Generate timestamp and log file name
# Pattern for generating date log file in /tmp dir (following shell-template.sh)
################################################################################
ts=`date +%Y-%m-%d_%H%M%S`
file=${script_name%.*}
log_file=/tmp/${file}_${ts}.txt

################################################################################
# Main script logic
################################################################################

cat<<EOF
================================================================================
Running test suite and saving output to: ${log_file}
================================================================================
EOF

# Change to project root directory (assuming script is in scripts/ subdirectory)
project_root=$(cd "${script_dir}/.." && pwd)
cd "${project_root}"

# Run tests and save output to log file
{
    echo "================================================================================
Test Run Started: $(date)
Log File: ${log_file}
================================================================================
"
    time make test-parallel
    echo "
================================================================================
Test Run Completed: $(date)
================================================================================
"
} 2>&1 | tee "${log_file}"

# Check exit code from make test-parallel
test_exit_code=${PIPESTATUS[0]}

cat<<EOF
================================================================================
Parsing test results from: ${log_file}
================================================================================
EOF

# Check for "error" or "failed" strings in the log file (case-insensitive)
errors_found=false

# Check for "error" (case-insensitive)
if grep -qi "error" "${log_file}"; then
    echo "❌ Found 'error' in test output"
    errors_found=true
fi

# Check for "failed" (case-insensitive)
if grep -qi "failed" "${log_file}"; then
    echo "❌ Found 'failed' in test output"
    errors_found=true
fi

# Also check for specific failure patterns
if grep -qi "FAILED\|ERROR" "${log_file}"; then
    echo "❌ Found test failure indicators (FAILED/ERROR)"
    errors_found=true
fi

# Check for pytest failure summary
if grep -qiE "[0-9]+\s+failed" "${log_file}"; then
    echo "❌ Found pytest failure count in output"
    errors_found=true
fi

# Check for version test failures
if grep -qi "❌ Failed:" "${log_file}"; then
    echo "❌ Found version test failures"
    errors_found=true
fi

cat<<EOF
================================================================================
Test Verification Results
================================================================================
Log File: ${log_file}
Test Exit Code: ${test_exit_code}
Errors/Failures Found: ${errors_found}
================================================================================
EOF

# Determine final status
if [ "${errors_found}" = "true" ] || [ "${test_exit_code}" -ne 0 ]; then
    echo "❌ TESTS HAVE NOT PASSED"
    echo "Status: FAIL"
    exit 1
else
    echo "✓ ALL TESTS PASSED"
    echo "Status: PASS"
    exit 0
fi
