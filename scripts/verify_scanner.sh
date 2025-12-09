#!/usr/bin/env bash
set -euET -o pipefail

script_name=$(basename $0)
script_dir=$(dirname $0)

################################################################################
# Scanner Verification Script
#
# This script verifies that the react2shell-scanner correctly detects
# vulnerabilities when scanning the application with different React versions.
################################################################################

################################################################################
# CLI Parameters
################################################################################
SAFE_CHECK=false
TEST_ALL_VERSIONS=false
QUIET=false
VERBOSE=false

################################################################################
# Default values
################################################################################
SCANNER_PATH="/Users/lblackb/data/lblackb/git/third-party/react2shell-scanner"
SCANNER_SCRIPT="${SCANNER_PATH}/scanner.py"
FRONTEND_URL="http://localhost:5173"

# Vulnerable versions
VULNERABLE_VERSIONS=("19.0" "19.1.0" "19.1.1" "19.2.0")
# Fixed versions
FIXED_VERSIONS=("19.0.1" "19.1.2" "19.2.1")

# Log file setup
ts=$(date +%Y-%m-%d_%H%M%S)
# Create temp file with mktemp to get unique random suffix
temp_file=$(mktemp "/tmp/${script_name%.*}_${ts}_XXXXXX") || exit 1
# Extract random suffix and create log file with .txt extension
random_part=$(basename "${temp_file}" | sed "s/${script_name%.*}_${ts}_//")
log_file="/tmp/${script_name%.*}_${ts}_${random_part}.txt"
# Remove temp file created by mktemp and create our log file
rm -f "${temp_file}"
touch "${log_file}" || exit 1
# Cleanup log file on exit (optional - comment out if you want to keep logs)
# trap "rm -f ${log_file}" EXIT

################################################################################
# Colors
################################################################################
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

################################################################################
# Show command usage
################################################################################
function usage {
    message=${1:-}
    if [ ! -z "${message}" ] ; then
	echo "Message: ${message}" >&2
    fi
    cat<<EOF
Usage: ${script_name} [-hqv] [-s] [-a]

This script verifies that the react2shell-scanner correctly detects
vulnerabilities when scanning the application with different React versions.

Options:
  -h               : Display this help message.
  -s               : Use safe side-channel detection instead of RCE PoC
  -a               : Test all versions (default: only vulnerable versions)
  -q               : Quiet mode. Output as little as possible.
  -v               : Verbose output.

Example:
$ ${script_name} -s -a
EOF
}

################################################################################
# Get command line options
################################################################################
while getopts ":hqsav" opt; do
    case ${opt} in
	h )
            usage
            exit 0
            ;;
	q )
            QUIET=true
            ;;
	s )
            SAFE_CHECK=true
            ;;
	a )
            TEST_ALL_VERSIONS=true
            ;;
	v )
            VERBOSE=true
            ;;
	\? )
            usage "Invalid Option: -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

################################################################################
# Get project root
################################################################################
# Handle both direct execution and Makefile execution
# When called from Makefile, we're already in the project root
# When called directly, we need to find it relative to the script
if [ -f "Makefile" ] && [ -f "package.json" ]; then
    # We're already in the project root
    PROJECT_ROOT="$(pwd)"
else
    # Find project root relative to script location
    SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
    # Resolve to absolute path
    if [ -L "$SCRIPT_PATH" ]; then
        # If it's a symlink, resolve it
        SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH" 2>/dev/null || readlink "$SCRIPT_PATH")"
    fi
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || pwd)"
    # Go up one level from scripts/ directory
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
fi

# Ensure we have a valid project root
if [ ! -f "${PROJECT_ROOT}/Makefile" ] || [ ! -f "${PROJECT_ROOT}/package.json" ]; then
    echo "Error: Could not determine project root. Make sure you're running from the project directory." >&2
    exit 1
fi

################################################################################
# Functions
################################################################################

# Function to check if server is running
function check_server {
    if curl -s -f "${FRONTEND_URL}" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for server
function wait_for_server {
    local max_attempts=30
    local attempt=0
    
    ${QUIET} || echo "${cyan}Waiting for server to be ready...${reset}"
    while [ $attempt -lt $max_attempts ]; do
        if check_server; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo "${red}Error: Server not ready after ${max_attempts} seconds${reset}" >&2
    return 1
}

# Function to switch React version
function switch_version {
    local version=$1
    ${QUIET} || echo "${cyan}Switching to React ${version}...${reset}"
    
    local original_dir="$(pwd)"
    cd "$PROJECT_ROOT" || {
        echo "${red}Error: Cannot change to project root: ${PROJECT_ROOT}${reset}" >&2
        return 1
    }
    if make "react-${version}" > /dev/null 2>&1; then
        ${QUIET} || echo "${green}✓ Switched to React ${version}${reset}"
        cd "$original_dir"
        return 0
    else
        echo "${red}✗ Failed to switch to React ${version}${reset}" >&2
        cd "$original_dir"
        return 1
    fi
}

# Function to run scanner
function run_scanner {
    local version=$1
    local expected_vulnerable=$2
    local scanner_args=("-u" "${FRONTEND_URL}" "--insecure" "--no-color")
    
    if [ "${SAFE_CHECK}" == true ]; then
        scanner_args+=("--safe-check")
    fi
    
    ${QUIET} || echo "${cyan}Running scanner against React ${version}...${reset}"
    
    local result
    result=$(python3 "$SCANNER_SCRIPT" "${scanner_args[@]}" 2>&1) || true
    local exit_code=$?
    
    ${VERBOSE} && cat<<EOF
Scanner output for React ${version}:
${result}
EOF
    
    # Check if vulnerable was detected
    if echo "$result" | grep -q "\[VULNERABLE\]"; then
        local detected_vulnerable=true
    else
        local detected_vulnerable=false
    fi
    
    # Verify detection matches expectation
    if [ "${expected_vulnerable}" == true ] && [ "${detected_vulnerable}" == true ]; then
        echo "${green}✓ Correctly detected vulnerability for React ${version}${reset}"
        return 0
    elif [ "${expected_vulnerable}" == false ] && [ "${detected_vulnerable}" == false ]; then
        echo "${green}✓ Correctly did NOT detect vulnerability for React ${version}${reset}"
        return 0
    elif [ "${expected_vulnerable}" == true ] && [ "${detected_vulnerable}" == false ]; then
        echo "${red}✗ FAILED: Should detect vulnerability for React ${version} but did not${reset}" >&2
        ${VERBOSE} || echo "$result"
        return 1
    else
        echo "${red}✗ FAILED: Should NOT detect vulnerability for React ${version} but did${reset}" >&2
        ${VERBOSE} || echo "$result"
        return 1
    fi
}

################################################################################
# Main script logic
################################################################################

function main {
    # Display log file location
    cat<<EOF
${cyan}========================================${reset}
${cyan}Scanner Verification Test${reset}
${cyan}========================================${reset}
${cyan}Log file: ${log_file}${reset}

EOF

    # Check if scanner exists
    if [ ! -f "$SCANNER_SCRIPT" ]; then
        echo "${red}Error: Scanner not found at ${SCANNER_SCRIPT}${reset}" >&2
        return 1
    fi

    # Check if Python is available
    if ! command -v python3 &> /dev/null; then
        echo "${red}Error: python3 not found${reset}" >&2
        return 1
    fi

    ${VERBOSE} && cat<<EOF
################################################################################
# Configuration
################################################################################
SCANNER_PATH=[${SCANNER_PATH}]
SCANNER_SCRIPT=[${SCANNER_SCRIPT}]
FRONTEND_URL=[${FRONTEND_URL}]
PROJECT_ROOT=[${PROJECT_ROOT}]
SAFE_CHECK=[${SAFE_CHECK}]
TEST_ALL_VERSIONS=[${TEST_ALL_VERSIONS}]
QUIET=[${QUIET}]
VERBOSE=[${VERBOSE}]

EOF

    # Ensure server is running
    if ! check_server; then
        ${QUIET} || echo "${yellow}Server not running. Starting servers...${reset}"
        original_dir="$(pwd)"
        cd "$PROJECT_ROOT" || {
            echo "${red}Error: Cannot change to project root: ${PROJECT_ROOT}${reset}" >&2
            return 1
        }
        make start > /dev/null 2>&1
        cd "$original_dir"
        sleep 5
    fi

    if ! wait_for_server; then
        echo "${red}Error: Could not start server${reset}" >&2
        return 1
    fi

    # Track results
    PASSED=0
    FAILED=0

    # Test vulnerable versions
    ${QUIET} || echo "${cyan}Testing VULNERABLE versions...${reset}"
    for version in "${VULNERABLE_VERSIONS[@]}"; do
        if switch_version "$version"; then
            sleep 3  # Wait for npm install and server restart
            if wait_for_server; then
                if run_scanner "$version" true; then
                    PASSED=$((PASSED + 1))
                else
                    FAILED=$((FAILED + 1))
                fi
            else
                echo "${red}✗ Server not ready after switching to ${version}${reset}" >&2
                FAILED=$((FAILED + 1))
            fi
        else
            FAILED=$((FAILED + 1))
        fi
        ${QUIET} || echo ""
    done

    # Test fixed versions if requested
    if [ "${TEST_ALL_VERSIONS}" == true ]; then
        ${QUIET} || echo "${cyan}Testing FIXED versions...${reset}"
        for version in "${FIXED_VERSIONS[@]}"; do
            if switch_version "$version"; then
                sleep 3  # Wait for npm install and server restart
                if wait_for_server; then
                    if run_scanner "$version" false; then
                        PASSED=$((PASSED + 1))
                    else
                        FAILED=$((FAILED + 1))
                    fi
                else
                    echo "${red}✗ Server not ready after switching to ${version}${reset}" >&2
                    FAILED=$((FAILED + 1))
                fi
            else
                FAILED=$((FAILED + 1))
            fi
            ${QUIET} || echo ""
        done
    fi

    # Summary
    cat<<EOF
${cyan}========================================${reset}
${cyan}Test Summary${reset}
${cyan}========================================${reset}
Passed: ${green}${PASSED}${reset}
Failed: ${red}${FAILED}${reset}

EOF

    if [ ${FAILED} -eq 0 ]; then
        echo "${green}All tests passed!${reset}"
        return 0
    else
        echo "${red}Some tests failed!${reset}" >&2
        return 1
    fi
}

# Execute main function and capture output to log file
# Use process substitution to tee output while preserving exit codes
main 2>&1 | tee "${log_file}"
exit_code=${PIPESTATUS[0]}
exit ${exit_code}
