#!/bin/bash
#
# Scanner Verification Script
#
# This script verifies that the react2shell-scanner correctly detects
# vulnerabilities when scanning the application with different React versions.
#
# Usage:
#   ./scripts/verify_scanner.sh [--safe-check] [--all-versions]
#
# Options:
#   --safe-check    Use safe side-channel detection instead of RCE PoC
#   --all-versions  Test all versions (default: only vulnerable versions)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCANNER_PATH="/Users/lblackb/data/lblackb/git/third-party/react2shell-scanner"
SCANNER_SCRIPT="${SCANNER_PATH}/scanner.py"

# Get project root - handle both direct execution and Makefile execution
# Use a more robust method that works when called from Makefile
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback if BASH_SOURCE is not available
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Clean any newlines or extra whitespace from path
PROJECT_ROOT="$(echo "${PROJECT_ROOT}" | tr -d '\n\r' | xargs)"

FRONTEND_URL="http://localhost:5173"
SAFE_CHECK=false
TEST_ALL_VERSIONS=false

# Vulnerable versions
VULNERABLE_VERSIONS=("19.0" "19.1.0" "19.1.1" "19.2.0")
# Fixed versions
FIXED_VERSIONS=("19.0.1" "19.1.2" "19.2.1")

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --safe-check)
            SAFE_CHECK=true
            shift
            ;;
        --all-versions)
            TEST_ALL_VERSIONS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--safe-check] [--all-versions]"
            exit 1
            ;;
    esac
done

# Check if scanner exists
if [ ! -f "$SCANNER_SCRIPT" ]; then
    echo -e "${RED}Error: Scanner not found at ${SCANNER_SCRIPT}${NC}"
    exit 1
fi

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 not found${NC}"
    exit 1
fi

# Function to check if server is running
check_server() {
    if curl -s -f "${FRONTEND_URL}" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for server
wait_for_server() {
    local max_attempts=30
    local attempt=0
    
    echo -e "${CYAN}Waiting for server to be ready...${NC}"
    while [ $attempt -lt $max_attempts ]; do
        if check_server; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}Error: Server not ready after ${max_attempts} seconds${NC}"
    return 1
}

# Function to switch React version
switch_version() {
    local version=$1
    echo -e "${CYAN}Switching to React ${version}...${NC}"
    
    local original_dir="$(pwd)"
    cd "$PROJECT_ROOT" || {
        echo -e "${RED}Error: Cannot change to project root: ${PROJECT_ROOT}${NC}"
        return 1
    }
    if make "react-${version}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Switched to React ${version}${NC}"
        cd "$original_dir"
        return 0
    else
        echo -e "${RED}✗ Failed to switch to React ${version}${NC}"
        cd "$original_dir"
        return 1
    fi
}

# Function to run scanner
run_scanner() {
    local version=$1
    local expected_vulnerable=$2
    local scanner_args=("-u" "${FRONTEND_URL}" "--insecure" "--no-color")
    
    if [ "$SAFE_CHECK" = true ]; then
        scanner_args+=("--safe-check")
    fi
    
    echo -e "${CYAN}Running scanner against React ${version}...${NC}"
    
    local result
    result=$(python3 "$SCANNER_SCRIPT" "${scanner_args[@]}" 2>&1)
    local exit_code=$?
    
    # Check if vulnerable was detected
    if echo "$result" | grep -q "\[VULNERABLE\]"; then
        local detected_vulnerable=true
    else
        local detected_vulnerable=false
    fi
    
    # Verify detection matches expectation
    if [ "$expected_vulnerable" = true ] && [ "$detected_vulnerable" = true ]; then
        echo -e "${GREEN}✓ Correctly detected vulnerability for React ${version}${NC}"
        return 0
    elif [ "$expected_vulnerable" = false ] && [ "$detected_vulnerable" = false ]; then
        echo -e "${GREEN}✓ Correctly did NOT detect vulnerability for React ${version}${NC}"
        return 0
    elif [ "$expected_vulnerable" = true ] && [ "$detected_vulnerable" = false ]; then
        echo -e "${RED}✗ FAILED: Should detect vulnerability for React ${version} but did not${NC}"
        echo "$result"
        return 1
    else
        echo -e "${RED}✗ FAILED: Should NOT detect vulnerability for React ${version} but did${NC}"
        echo "$result"
        return 1
    fi
}

# Main execution
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Scanner Verification Test${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Ensure server is running
if ! check_server; then
    echo -e "${YELLOW}Server not running. Starting servers...${NC}"
    local original_dir="$(pwd)"
    cd "$PROJECT_ROOT" || {
        echo -e "${RED}Error: Cannot change to project root: ${PROJECT_ROOT}${NC}"
        exit 1
    }
    make start > /dev/null 2>&1
    cd "$original_dir"
    sleep 5
fi

if ! wait_for_server; then
    echo -e "${RED}Error: Could not start server${NC}"
    exit 1
fi

# Track results
PASSED=0
FAILED=0

# Test vulnerable versions
echo -e "${CYAN}Testing VULNERABLE versions...${NC}"
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
            echo -e "${RED}✗ Server not ready after switching to ${version}${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Test fixed versions if requested
if [ "$TEST_ALL_VERSIONS" = true ]; then
    echo -e "${CYAN}Testing FIXED versions...${NC}"
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
                echo -e "${RED}✗ Server not ready after switching to ${version}${NC}"
                FAILED=$((FAILED + 1))
            fi
        else
            FAILED=$((FAILED + 1))
        fi
        echo ""
    done
fi

# Summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Test Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
