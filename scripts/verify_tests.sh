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

# Parse test results from log file
errors_found=false

# Check for actual pytest test failures in summary lines
# Look for patterns like "X failed" or "Y errors" in pytest summary
if grep -qE "[0-9]+\s+failed|[0-9]+\s+errors" "${log_file}"; then
    # Extract failure counts from summary lines
    failed_count=$(grep -oE "[0-9]+\s+failed" "${log_file}" | head -1 | grep -oE "[0-9]+" || echo "0")
    error_count=$(grep -oE "[0-9]+\s+errors" "${log_file}" | head -1 | grep -oE "[0-9]+" || echo "0")
    
    # Check if there are actual failures (not just the word appearing in logs)
    if [ "${failed_count}" -gt 0 ] || [ "${error_count}" -gt 0 ]; then
        echo "❌ Found test failures: ${failed_count} failed, ${error_count} errors"
        errors_found=true
    fi
fi

# Check for specific test failure markers (FAILED tests/ or ERROR tests/)
if grep -qE "FAILED tests/|ERROR tests/" "${log_file}"; then
    echo "❌ Found test failure markers (FAILED tests/ or ERROR tests/)"
    errors_found=true
fi

# Check for version test failures (❌ Failed: pattern)
if grep -q "❌ Failed:" "${log_file}"; then
    echo "❌ Found version test failures"
    errors_found=true
fi

# Check for pytest failure section header
if grep -q "===.*FAILURES.*===" "${log_file}"; then
    echo "❌ Found pytest FAILURES section"
    errors_found=true
fi

# Check for pytest errors section header  
if grep -q "===.*ERRORS.*===" "${log_file}"; then
    echo "❌ Found pytest ERRORS section"
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
