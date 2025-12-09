#!/usr/bin/env bash
set -euET -o pipefail

script_name=$(basename $0)
script_dir=$(dirname $0)

################################################################################
# Scanner Verification Script
#
# This script verifies that the react2shell-scanner correctly detects
# vulnerabilities when scanning Next.js applications with different Next.js versions.
# Note: The scanner is designed exclusively for Next.js applications with RSC.
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
# FRONTEND_URL will be set after framework detection

# Vulnerable Next.js versions (scanner tests Next.js, not React)
NEXTJS_VULNERABLE_VERSIONS=("14.0.0" "14.1.0" "15.0.0" "15.1.0")
# Fixed Next.js versions
NEXTJS_FIXED_VERSIONS=("14.0.1" "14.1.1")

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
vulnerabilities when scanning Next.js applications with different Next.js versions.

Note: The scanner is designed exclusively for Next.js applications with React Server Components.
This script requires the project to be in Next.js mode (run 'make use-nextjs' first).

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
# Framework detection and port configuration
################################################################################
# Detect framework mode from .framework-mode file
FRAMEWORK_MODE=$(cat "${PROJECT_ROOT}/.framework-mode" 2>/dev/null | tr -d '[:space:]' || echo "vite")

# Set FRONTEND_URL based on framework mode
if [ "${FRAMEWORK_MODE}" == "nextjs" ]; then
    FRONTEND_URL="http://localhost:3000"
else
    FRONTEND_URL="http://localhost:5173"
fi

################################################################################
# Functions
################################################################################

# Function to check if server is running (GET request)
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
    
    ${QUIET} || echo "${cyan}Waiting for server to be ready at ${FRONTEND_URL}...${reset}"
    
    # First, wait for basic GET request to succeed
    while [ $attempt -lt $max_attempts ]; do
        if check_server; then
            break
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -ge $max_attempts ]; then
        echo "${red}Error: Server not ready after ${max_attempts} seconds at ${FRONTEND_URL}${reset}" >&2
        echo "${yellow}Note: Check if framework mode (${FRAMEWORK_MODE}) matches the running server${reset}" >&2
        return 1
    fi
    
    # Server is ready (GET request succeeded)
    return 0
}

# Function to switch Next.js version
function switch_version {
    local version=$1
    ${QUIET} || echo "${cyan}Switching to Next.js ${version}...${reset}"
    
    # Verify we're in Next.js mode
    if [ "${FRAMEWORK_MODE}" != "nextjs" ]; then
        echo "${red}Error: Scanner verification requires Next.js mode. Run 'make use-nextjs' first.${reset}" >&2
        return 1
    fi
    
    local original_dir="$(pwd)"
    cd "$PROJECT_ROOT" || {
        echo "${red}Error: Cannot change to project root: ${PROJECT_ROOT}${reset}" >&2
        return 1
    }
    
    # Switch version and capture output to check for errors
    local switch_output
    switch_output=$(make "nextjs-${version}" 2>&1)
    local switch_exit=$?
    
    if [ $switch_exit -eq 0 ]; then
        ${QUIET} || echo "${green}✓ Switched to Next.js ${version}${reset}"
        
        # Verify next binary exists after installation
        if [ ! -f "${PROJECT_ROOT}/frameworks/nextjs/node_modules/.bin/next" ]; then
            echo "${yellow}Warning: next binary not found after installation. Waiting 5 seconds and checking again...${reset}" >&2
            sleep 5
            if [ ! -f "${PROJECT_ROOT}/frameworks/nextjs/node_modules/.bin/next" ]; then
                echo "${red}Error: next binary still not found after installation${reset}" >&2
                ${VERBOSE} && echo "$switch_output" >&2
                cd "$original_dir"
                return 1
            fi
        fi
        
        cd "$original_dir"
        return 0
    else
        echo "${red}✗ Failed to switch to Next.js ${version}${reset}" >&2
        ${VERBOSE} && echo "$switch_output" >&2
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
    
    ${QUIET} || echo "${cyan}Running scanner against Next.js ${version}...${reset}"
    
    local result
    result=$(python3 "$SCANNER_SCRIPT" "${scanner_args[@]}" 2>&1) || true
    local exit_code=$?
    
    # Always show scanner output (unless quiet mode)
    if [ "${QUIET}" != true ]; then
        echo "$result"
        echo ""  # Blank line after scanner output
    fi
    
    # Check if vulnerable was detected
    if echo "$result" | grep -q "\[VULNERABLE\]"; then
        local detected_vulnerable=true
    else
        local detected_vulnerable=false
    fi
    
    # Verify detection matches expectation
    if [ "${expected_vulnerable}" == true ] && [ "${detected_vulnerable}" == true ]; then
        echo "${green}✓ Correctly detected vulnerability for Next.js ${version}${reset}"
        return 0
    elif [ "${expected_vulnerable}" == false ] && [ "${detected_vulnerable}" == false ]; then
        echo "${green}✓ Correctly did NOT detect vulnerability for Next.js ${version}${reset}"
        return 0
    elif [ "${expected_vulnerable}" == true ] && [ "${detected_vulnerable}" == false ]; then
        echo "${red}✗ FAILED: Should detect vulnerability for Next.js ${version} but did not${reset}" >&2
        return 1
    else
        echo "${red}✗ FAILED: Should NOT detect vulnerability for Next.js ${version} but did${reset}" >&2
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

    # Display framework detection (unless quiet)
    ${QUIET} || echo "${cyan}Detected framework: ${FRAMEWORK_MODE} (checking port ${FRONTEND_URL#http://localhost:})${reset}"

    ${VERBOSE} && cat<<EOF
################################################################################
# Configuration
################################################################################
SCANNER_PATH=[${SCANNER_PATH}]
SCANNER_SCRIPT=[${SCANNER_SCRIPT}]
FRAMEWORK_MODE=[${FRAMEWORK_MODE}]
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
        echo "${red}Error: Could not start server or server not accessible at ${FRONTEND_URL}${reset}" >&2
        echo "${yellow}Framework mode: ${FRAMEWORK_MODE}${reset}" >&2
        echo "${yellow}Expected port: ${FRONTEND_URL#http://localhost:}${reset}" >&2
        echo "${yellow}Try: make status (to check which servers are running)${reset}" >&2
        return 1
    fi

    # Track results
    PASSED=0
    FAILED=0
    PASSED_VERSIONS=()
    FAILED_VERSIONS=()

    # Verify we're in Next.js mode (scanner only works with Next.js)
    if [ "${FRAMEWORK_MODE}" != "nextjs" ]; then
        echo "${red}Error: Scanner verification requires Next.js mode.${reset}" >&2
        echo "${yellow}The react2shell-scanner is designed exclusively for Next.js applications.${reset}" >&2
        echo "${yellow}Run 'make use-nextjs' to switch to Next.js mode, then try again.${reset}" >&2
        return 1
    fi

    # Test vulnerable Next.js versions
    ${QUIET} || echo "${cyan}Testing VULNERABLE Next.js versions...${reset}"
    for version in "${NEXTJS_VULNERABLE_VERSIONS[@]}"; do
        if switch_version "$version"; then
            # Restart server after version switch to ensure new version is loaded
            ${QUIET} || echo "${cyan}Restarting server with Next.js ${version}...${reset}"
            original_dir="$(pwd)"
            cd "$PROJECT_ROOT" || {
                echo "${red}Error: Cannot change to project root: ${PROJECT_ROOT}${reset}" >&2
                FAILED=$((FAILED + 1))
                FAILED_VERSIONS+=("${version} (vulnerable - cannot access project root)")
                continue
            }
            
            # Verify next binary exists before starting server
            if [ ! -f "frameworks/nextjs/node_modules/.bin/next" ]; then
                echo "${yellow}Warning: next binary not found. Waiting 5 seconds for npm install to complete...${reset}" >&2
                sleep 5
                if [ ! -f "frameworks/nextjs/node_modules/.bin/next" ]; then
                    echo "${red}Error: next binary not found after installation. Cannot start server.${reset}" >&2
                    cd "$original_dir"
                    FAILED=$((FAILED + 1))
                    FAILED_VERSIONS+=("${version} (vulnerable - next binary not found)")
                    continue
                fi
            fi
            
            make stop > /dev/null 2>&1
            sleep 3  # Longer pause to ensure server fully stops
            make start > /dev/null 2>&1
            cd "$original_dir"
            
            # wait_for_server will poll and detect when server is ready
            # (includes GET check + POST/RSC readiness check for Next.js)
            if wait_for_server; then
                if run_scanner "$version" true; then
                    PASSED=$((PASSED + 1))
                    PASSED_VERSIONS+=("${version} (vulnerable)")
                else
                    FAILED=$((FAILED + 1))
                    FAILED_VERSIONS+=("${version} (vulnerable)")
                fi
            else
                echo "${red}✗ Server not ready after switching to ${version}${reset}" >&2
                FAILED=$((FAILED + 1))
                FAILED_VERSIONS+=("${version} (vulnerable - server not ready)")
            fi
        else
            FAILED=$((FAILED + 1))
            FAILED_VERSIONS+=("${version} (vulnerable - switch failed)")
        fi
        ${QUIET} || echo ""
    done

    # Test fixed Next.js versions if requested
    if [ "${TEST_ALL_VERSIONS}" == true ]; then
        ${QUIET} || echo "${cyan}Testing FIXED Next.js versions...${reset}"
        for version in "${NEXTJS_FIXED_VERSIONS[@]}"; do
            if switch_version "$version"; then
                # Restart server after version switch to ensure new version is loaded
                ${QUIET} || echo "${cyan}Restarting server with Next.js ${version}...${reset}"
                original_dir="$(pwd)"
                cd "$PROJECT_ROOT" || {
                    echo "${red}Error: Cannot change to project root: ${PROJECT_ROOT}${reset}" >&2
                    FAILED=$((FAILED + 1))
                    FAILED_VERSIONS+=("${version} (fixed - cannot access project root)")
                    continue
                }
                
                # Verify next binary exists before starting server
                if [ ! -f "frameworks/nextjs/node_modules/.bin/next" ]; then
                    echo "${yellow}Warning: next binary not found. Waiting 5 seconds for npm install to complete...${reset}" >&2
                    sleep 5
                    if [ ! -f "frameworks/nextjs/node_modules/.bin/next" ]; then
                        echo "${red}Error: next binary not found after installation. Cannot start server.${reset}" >&2
                        cd "$original_dir"
                        FAILED=$((FAILED + 1))
                        FAILED_VERSIONS+=("${version} (fixed - next binary not found)")
                        continue
                    fi
                fi
                
                make stop > /dev/null 2>&1
                sleep 3  # Longer pause to ensure server fully stops
                make start > /dev/null 2>&1
                cd "$original_dir"
                
                # wait_for_server will poll and detect when server is ready
                # (includes GET check + POST/RSC readiness check for Next.js)
                if wait_for_server; then
                    if run_scanner "$version" false; then
                        PASSED=$((PASSED + 1))
                        PASSED_VERSIONS+=("${version} (fixed)")
                    else
                        FAILED=$((FAILED + 1))
                        FAILED_VERSIONS+=("${version} (fixed)")
                    fi
                else
                    echo "${red}✗ Server not ready after switching to ${version}${reset}" >&2
                    FAILED=$((FAILED + 1))
                    FAILED_VERSIONS+=("${version} (fixed - server not ready)")
                fi
            else
                FAILED=$((FAILED + 1))
                FAILED_VERSIONS+=("${version} (fixed - switch failed)")
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

    # Display passed versions
    if [ ${#PASSED_VERSIONS[@]} -gt 0 ]; then
        echo "${green}Passed Versions:${reset}"
        for version in "${PASSED_VERSIONS[@]}"; do
            echo "  ${green}✓${reset} Next.js ${version}"
        done
        echo ""
    fi

    # Display failed versions
    if [ ${#FAILED_VERSIONS[@]} -gt 0 ]; then
        echo "${red}Failed Versions:${reset}"
        for version in "${FAILED_VERSIONS[@]}"; do
            echo "  ${red}✗${reset} Next.js ${version}"
        done
        echo ""
    fi

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
